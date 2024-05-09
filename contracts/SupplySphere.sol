// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./Products.sol";
import "./Services.sol";
import "./Logistics.sol";
import "./SupplyChain.sol";
import "./RawMaterials.sol";

contract SupplySphere is Context, AccessControl {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Logistics logistics;
    Products products;
    RawMaterials rawMaterials;
    Services services;

    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");

    IERC20 public paymentToken;

    constructor(IERC20 _paymentToken) {
        paymentToken = _paymentToken;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Default admin setup
    }

    function registerUser(bytes32 role) public returns (bool) {
        return _grantRole(role, _msgSender());
    }

    // -----------------------------------------------------------------------
    // LOGISTICS
    // -----------------------------------------------------------------------

    function addLogistic(
        string calldata name,
        uint256 price
    ) external onlyRole(TRANSPORTER_ROLE) returns (uint256) {
        return logistics.addLogistics(name, price);
    }

    function removeLogistic(uint256 id) external onlyRole(TRANSPORTER_ROLE) {
        return logistics.removeLogistic(id);
    }

    function getLogistic(
        uint256 id
    ) public view returns (Logistics.Logistic memory) {
        return logistics.getLogistic(id);
    }

    function getAllLogistics()
        public
        view
        returns (Logistics.Logistic[] memory)
    {
        return logistics.getAllLogistics();
    }

    // -----------------------------------------------------------------------
    // Products
    // -----------------------------------------------------------------------

    function addProduct(
        string calldata name,
        uint256 price,
        uint256 tax,
        uint256 quantity
    ) external onlyRole(MANUFACTURER_ROLE) returns (uint256) {
        return products.addProduct(name, price, tax, quantity);
    }

    function removeProduct(uint256 id) external onlyRole(MANUFACTURER_ROLE) {
        return products.removeProduct(id);
    }

    function getProduct(
        uint256 id
    ) public view returns (Products.Product memory) {
        return products.getProduct(id);
    }

    function getAllProducts() public view returns (Products.Product[] memory) {
        return products.getAllProducts();
    }

    // -----------------------------------------------------------------------
    // RAW MATERIALS
    // -----------------------------------------------------------------------
    function addRawMaterial(
        string calldata name,
        uint256 price,
        uint256 tax,
        uint256 quantity
    ) external onlyRole(SELLER_ROLE) returns (uint256) {
        return rawMaterials.addRawMaterial(name, price, tax, quantity);
    }

    function removeRawMaterial(uint256 id) external onlyRole(SELLER_ROLE) {
        return rawMaterials.removeRawMaterial(id);
    }

    function getRawMaterial(
        uint256 id
    ) public view returns (RawMaterials.RawMaterial memory) {
        return rawMaterials.getRawMaterial(id);
    }

    function getAllRawMaterials()
        public
        view
        returns (RawMaterials.RawMaterial[] memory)
    {
        return rawMaterials.getAllRawMaterials();
    }

    // -----------------------------------------------------------------------
    // SERVICES
    // -----------------------------------------------------------------------

    function addService(
        string calldata name,
        uint256 price,
        uint256 tax,
        uint256 quantity,
        uint256 volume
    ) external onlyRole(SELLER_ROLE) returns (uint256) {
        return services.addService(name, price, tax, quantity, volume);
    }

    function removeService(uint256 id) external onlyRole(SELLER_ROLE) {
        return services.removeService(id);
    }

    function getService(uint256 id) public view returns (Service memory) {
        return services.getService(id);
    }

    function getAllServices() public view returns (Service[] memory) {
        return services.getAllServices();
    }

    // -----------------------------------------------------------------------
    // SERVICES
    // -----------------------------------------------------------------------

    function createSupplyChain(
        string memory name,
        string memory description,
        StepInput[] memory _steps
    ) public returns (uint256) {
        chainIdCounter.increment();
        uint256 chainId = chainIdCounter.current();

        Chain storage newChain = supplychains[chainId];
        newChain.id = chainId;
        newChain.name = name;
        newChain.description = description;
        newChain.totalFundedAmount = 0;
        newChain.isFunded = false;
        newChain.isActive = false;
        newChain.owner = _msgSender();

        uint256 localStepIdCounter = 0;

        for (uint256 i = 0; i < _steps.length; i++) {
            uint256 stepId = localStepIdCounter;
            localStepIdCounter++;

            uint256 totalCost;
            uint256 logisticsCost;
            uint256 itemCost;

            address transporter;
            address sender;

            Logistic memory logistic = getLogistic(_steps[i].logisticsId);
            // logisticsCost = logistic.price * _step[i].quantity;
            logisticsCost = logistic.price;
            transporter = logistic.owner;

            if (_steps[i].stepType == StepType.Procuring) {
                Product memory product = getProduct(_steps[i].itemId);
                itemCost = product.price * _steps[i].quantity;
                sender = product.owner;
            } else if (_steps[i].stepType == StepType.Servicing) {
                Service memory service = getService(_steps[i].itemId);
                itemCost = service.price * _steps[i].quantity;
                sender = service.owner;
            }

            totalCost = logisticsCost + itemCost;

            Step memory newStep = Step({
                stepId: stepId,
                stepType: _steps[i].stepType,
                itemId: _steps[i].itemId,
                logisticsId: _steps[i].logisticsId,
                quantity: _steps[i].quantity,
                logisticsCost: logisticsCost,
                itemCost: itemCost,
                totalCost: totalCost,
                sender: sender,
                transporter: transporter,
                receiver: _steps[i].receiver,
                senderConfirmed: false,
                transporterReceived: false,
                transporterDelivered: false,
                receiverConfirmed: false
            });

            newChain.steps.push(newStep);
            newChain.totalFundedAmount += totalCost;
        }

        chainIds.add(chainId);
        return chainId;
    }

    // -----------------------------------------------------------------------

    function confirmSender(uint256 supplyChainId, uint256 stepId) external {
        if (!hasRole(SELLER_ROLE, _msgSender())) {
            revert AccessControlUnauthorizedAccount(
                _msgSender(),
                "Unauthorized Role"
            );
        }

        Step storage step = supplychains[supplyChainId].steps[stepId];
        step.senderConfirmed = true;
    }

    function confirmTransporterReceived(
        uint256 supplyChainId,
        uint256 stepId
    ) external onlyRole(TRANSPORTER_ROLE) {
        Step storage step = supplychains[supplyChainId].steps[stepId];
        step.transporterReceived = true;
    }

    function confirmTransporterDelivered(
        uint256 supplyChainId,
        uint256 stepId
    ) external onlyRole(TRANSPORTER_ROLE) {
        Step storage step = supplychains[supplyChainId].steps[stepId];
        step.transporterDelivered = true;
    }

    function confirmReceiver(uint256 supplyChainId, uint256 stepId) external {
        if (
            !(hasRole(SELLER_ROLE, _msgSender()) ||
                hasRole(MANUFACTURER_ROLE, _msgSender()))
        ) {
            revert AccessControlUnauthorizedAccount(
                _msgSender(),
                "Unauthorized Role"
            );
        }

        Step storage step = supplychains[supplyChainId].steps[stepId];
        step.receiverConfirmed = true;

        _releaseFunds(step);
    }

    // -----------------------------------------------------------------------

    function _releaseFunds(Step storage step) internal {
        require(_isStepCompleted(step), "Step confirmations incomplete");
        require(
            paymentToken.transfer(step.transporter, step.logisticsCost),
            "Failed to release funds"
        );
        require(
            paymentToken.transfer(step.sender, step.itemCost),
            "Failed to release funds"
        );
    }
}
