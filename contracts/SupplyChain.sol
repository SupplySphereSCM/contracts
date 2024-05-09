// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./libs/Counters.sol";

contract SupplyChain is Context {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

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

    function getSupplyChain(uint256 id) public view returns (Chain memory) {
        require(chainIds.contains(id), "SupplyChain does not exist");
        return supplychains[id];
    }

    function fundChain(
        uint256 chainId,
        IERC20 paymentToken
    ) public returns (bool) {
        Chain storage chain = supplychains[chainId];
        require(chain.owner == _msgSender(), "Unautorized Onwer");
        require(
            paymentToken.allowance(_msgSender(), address(this)) >=
                chain.totalFundedAmount,
            "Insufficient Allowance"
        );

        if (
            paymentToken.transferFrom(
                _msgSender(),
                address(this),
                chain.totalFundedAmount
            )
        ) {
            chain.isFunded = true;
            chain.isActive = true;
            return true;
        } else {
            return false;
        }
    }

    function _isStepCompleted(Step storage step) internal view returns (bool) {
        return
            step.senderConfirmed &&
            step.transporterReceived &&
            step.transporterDelivered &&
            step.receiverConfirmed;
    }
}
