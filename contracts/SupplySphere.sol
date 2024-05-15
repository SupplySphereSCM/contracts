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
    SupplyChain supplyChain;

    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant RETAILER_ROLE = keccak256("RETAILER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");

    IERC20 public paymentToken;

    constructor(
        IERC20 _paymentToken,
        Logistics _logistics,
        Products _products,
        RawMaterials _rawMaterials,
        Services _services,
        SupplyChain _supplyChain
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Default admin setup

        paymentToken = _paymentToken;

        logistics = Logistics(_logistics);
        products = Products(_products);
        rawMaterials = RawMaterials(_rawMaterials);
        services = Services(_services);
        supplyChain = SupplyChain(_supplyChain);
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

    function orderProduct(
        uint256 id,
        uint256 quantity
    ) external onlyRole(RETAILER_ROLE) {
        return products.orderProduct(id, quantity);
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

    function getService(
        uint256 id
    ) public view returns (Services.Service memory) {
        return services.getService(id);
    }

    function getAllServices() public view returns (Services.Service[] memory) {
        return services.getAllServices();
    }

    // -----------------------------------------------------------------------
    // SUPPLYCHAIN
    // -----------------------------------------------------------------------
    function createSupplyChain(
        string memory name,
        string memory description,
        SupplyChain.StepInput[] memory _steps
    ) external onlyRole(MANUFACTURER_ROLE) returns (uint256) {
        return supplyChain.createSupplyChain(name, description, _steps);
    }

    function getSupplyChain(
        uint256 id
    ) public view returns (SupplyChain.Chain memory) {
        return supplyChain.getSupplyChain(id);
    }

    // -----------------------------------------------------------------------

    function confirmSender(uint256 supplyChainId, uint256 stepId) external {
        if (!hasRole(SELLER_ROLE, _msgSender())) {
            revert AccessControlUnauthorizedAccount(
                _msgSender(),
                "Unauthorized Role"
            );
        }

        supplyChain._confirmSender(supplyChainId, stepId);
    }

    function confirmTransporterReceived(
        uint256 supplyChainId,
        uint256 stepId
    ) external onlyRole(TRANSPORTER_ROLE) {
        supplyChain._confirmTransporterReceived(supplyChainId, stepId);
    }

    function confirmTransporterDelivered(
        uint256 supplyChainId,
        uint256 stepId
    ) external onlyRole(TRANSPORTER_ROLE) {
        supplyChain._confirmTransporterDelivered(supplyChainId, stepId);
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

        supplyChain._confirmReceiver(supplyChainId, stepId);
        SupplyChain.Step memory step = supplyChain
            .getSupplyChain(supplyChainId)
            .steps[stepId];
        _releaseFunds(step);
    }

    function fundChain(uint256 chainId) public {
        SupplyChain.Chain memory chain = supplyChain.getSupplyChain(chainId);
        require(chain.owner == _msgSender(), "Unautorized Onwer");
        require(
            paymentToken.allowance(_msgSender(), address(this)) >=
                chain.totalFundedAmount,
            "Insufficient Allowance"
        );

        require(
            paymentToken.transferFrom(
                _msgSender(),
                address(this),
                chain.totalFundedAmount
            ),
            "Payment Failed"
        );

        supplyChain._setFundChain(chainId);
    }

    // -----------------------------------------------------------------------

    function _releaseFunds(SupplyChain.Step memory step) internal {
        require(
            supplyChain._isStepCompleted(step),
            "Step confirmations incomplete"
        );
        require(
            paymentToken.transfer(step.transporter, step.logisticsCost),
            "Failed to release funds"
        );
        require(
            paymentToken.transfer(step.sender, step.itemCost),
            "Failed to release funds"
        );
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        return tx.origin;
    }
}
