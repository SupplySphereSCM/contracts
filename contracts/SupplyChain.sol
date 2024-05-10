// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./Services.sol";
import "./Logistics.sol";
import "./RawMaterials.sol";

import "./libs/Counters.sol";

contract SupplyChain is Context {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    Logistics logistics;
    RawMaterials rawMaterials;
    Services services;

    constructor(
        Logistics _logistics,
        RawMaterials _rawMaterials,
        Services _services
    ) {
        logistics = Logistics(_logistics);
        rawMaterials = RawMaterials(_rawMaterials);
        services = Services(_services);
    }

    enum StepType {
        Procuring,
        Servicing
    }

    struct Step {
        uint256 stepId;
        StepType stepType;
        uint256 itemId;
        uint256 logisticsId;
        uint256 quantity;
        uint256 logisticsCost;
        uint256 itemCost;
        uint256 totalCost;
        address sender;
        address transporter;
        address receiver;
        bool senderConfirmed;
        bool transporterReceived;
        bool transporterDelivered;
        bool receiverConfirmed;
    }

    struct StepInput {
        StepType stepType;
        uint256 itemId;
        uint256 logisticsId;
        uint256 quantity;
        address receiver;
    }

    struct Chain {
        uint256 id;
        string name;
        string description;
        Step[] steps;
        uint256 totalFundedAmount;
        address owner;
        bool isFunded;
        bool isActive;
    }

    EnumerableSet.UintSet chainIds;
    mapping(uint256 => Chain) public supplychains;
    Counters.Counter public chainIdCounter;

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

            Logistics.Logistic memory logistic = logistics.getLogistic(
                _steps[i].logisticsId
            );
            // logisticsCost = logistic.price * _step[i].quantity;
            logisticsCost = logistic.price;
            transporter = logistic.owner;

            if (_steps[i].stepType == StepType.Procuring) {
                RawMaterials.RawMaterial memory material = rawMaterials
                    .getRawMaterial(_steps[i].itemId);
                itemCost = material.price * _steps[i].quantity;
                sender = material.owner;
            } else if (_steps[i].stepType == StepType.Servicing) {
                Services.Service memory service = services.getService(
                    _steps[i].itemId
                );
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

    function getSupplyChain(uint256 id) public view returns (Chain memory) {
        require(chainIds.contains(id), "SupplyChain does not exist");
        return supplychains[id];
    }

    function _setFundChain(uint256 chainId) public {
        Chain storage chain = supplychains[chainId];
        chain.isFunded = true;
        chain.isActive = true;
    }

    function _isStepCompleted(Step memory step) public pure returns (bool) {
        return
            step.senderConfirmed &&
            step.transporterReceived &&
            step.transporterDelivered &&
            step.receiverConfirmed;
    }

    // ----------------------------------------------

    function _confirmSender(uint256 supplyChainId, uint256 stepId) public {
        SupplyChain.Step storage step = supplychains[supplyChainId].steps[
            stepId
        ];
        step.senderConfirmed = true;
    }

    function _confirmTransporterReceived(
        uint256 supplyChainId,
        uint256 stepId
    ) public {
        SupplyChain.Step storage step = supplychains[supplyChainId].steps[
            stepId
        ];
        step.transporterReceived = true;
    }

    function _confirmTransporterDelivered(
        uint256 supplyChainId,
        uint256 stepId
    ) public {
        SupplyChain.Step storage step = supplychains[supplyChainId].steps[
            stepId
        ];
        step.transporterDelivered = true;
    }

    function _confirmReceiver(uint256 supplyChainId, uint256 stepId) public {
        SupplyChain.Step storage step = supplychains[supplyChainId].steps[
            stepId
        ];
        step.receiverConfirmed = true;
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
