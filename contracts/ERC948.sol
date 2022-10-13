// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract ERC948 {

    enum PeriodType {
        Second,
        Day, 
        Week, 
        Month,
        Year
    }

    struct Subscription {
        address owner;
        address payeeAddress;
        address tokenAddress;
        uint amountRecurring;
        uint amountInitial;
        uint periodType;
        uint periodMultiplier;
        uint startTime;
        string data;
        bool active;
        uint nextPaymentTime;
        // uint terminationDate;
    }

    mapping (bytes32 => Subscription) public subscriptions;
    mapping (address => bytes32[]) public subscribers_subscriptions;

    event NewSubscription(
        bytes32 _subscriptionId,
        address _payeeAddress,
        address _tokenAddress,
        uint _amountRecurring,
        uint _amountInitial,
        uint _periodType, 
        uint _periodMultiplier,
        uint _startTime
        );

    function createSubscription(
        address _payeeAddress,
        address _tokenAddress,
        uint _amountRecurring,
        uint _amountInitial,
        uint _periodType,
        uint _periodMultiplier,
        uint _startTime,
        string _data
        )
        public
        returns (bytes32)
    {
        require((_periodType == 0),
                'Only period types of second are supported');

        require((_startTime >= block.timestamp),
                'Subscription must not start in the past');

        StandardToken token = StandardToken(_tokenAddress);
        uint amountRequired = _amountInitial + _amountRecurring;
        require((token.balanceOf(msg.sender) >= amountRequired),
                'Insufficient balance for initial + 1x recurring amount');

        require((token.allowance(msg.sender, this) >= amountRequired),
                'Insufficient approval for initial + 1x recurring amount');

        Subscription memory newSubscription = Subscription({
            owner: msg.sender,
            payeeAddress: _payeeAddress,
            tokenAddress: _tokenAddress,
            amountRecurring: _amountRecurring,
            amountInitial: _amountInitial,
            periodType: _periodType,
            periodMultiplier: _periodMultiplier,

            startTime: block.timestamp,

            data: _data,
            active: true,

            nextPaymentTime: block.timestamp + _periodMultiplier
        });

        
        bytes32 subscriptionId = keccak256(msg.sender, block.timestamp);
        subscriptions[subscriptionId] = newSubscription;

        subscribers_subscriptions[msg.sender].push(subscriptionId);

        token.transferFrom(msg.sender, _payeeAddress, _amountInitial);

        emit NewSubscription(
            subscriptionId,
            _payeeAddress,
            _tokenAddress,
            _amountRecurring,
            _amountInitial,
            _periodType,
            _periodMultiplier,
            _startTime
            );

        return subscriptionId;
    }


    function getSubscribersSubscriptions(address _subscriber)
        public
        view
        returns (bytes32[])
    {
        return subscribers_subscriptions[_subscriber];
    }

    function cancelSubscription(bytes32 _subscriptionId)
        public
        returns (bool)
    {
        Subscription storage subscription = subscriptions[_subscriptionId];
        require((subscription.payeeAddress == msg.sender)
            || (subscription.owner == msg.sender));

        delete subscriptions[_subscriptionId];
        return true;
    }

    function paymentDue(bytes32 _subscriptionId)
        public
        view
        returns (bool)
    {
        Subscription memory subscription = subscriptions[_subscriptionId];

        require((subscription.active == true), 'Not an active subscription');

        require((subscription.startTime <= block.timestamp),
            'Subscription has not started yet');

        if (subscription.nextPaymentTime <= block.timestamp) {
            return true;
        }
        else {
            return false;
        }
    }

    function processSubscription(
        bytes32 _subscriptionId,
        uint _amount
        )
        public
        returns (bool)
    {
        Subscription storage subscription = subscriptions[_subscriptionId];

        require((_amount <= subscription.amountRecurring),
            'Requested amount is higher than authorized');

        require((paymentDue(_subscriptionId)),
            'A Payment is not due for this subscription');

        StandardToken token = StandardToken(subscription.tokenAddress);
        token.transferFrom(subscription.owner, subscription.payeeAddress, _amount);
        subscription.nextPaymentTime = subscription.nextPaymentTime + subscription.periodMultiplier;
        return true;
    }

}
