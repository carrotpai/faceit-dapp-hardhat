// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Account {
    uint constant DURATION = 7 days;

    event Received(address, uint, uint);
    event playerAccountCreated(
        address _player,
        uint _balance,
        uint _lastTimeClaimed,
        bool _created,
        bool _participant
    );
    event balanceChanged(
        address indexed _player,
        uint _newBalance,
        uint _gain,
        uint _timestamp
    );
    event playerHadParticipate(address _player, bool _participant);

    receive() external payable {
        emit Received(msg.sender, msg.value, block.timestamp);
        console.log("received: %s", address(this).balance);
    }

    fallback() external payable {}

    modifier onlyOwner() {
        require(msg.sender == faceitOwner, "you are not a owner!");
        _;
    }

    modifier onlyRegistredPlayer() {
        require(balances[msg.sender].created);
        _;
    }

    modifier onlyParticipant() {
        require(balances[msg.sender].participant);
        _;
    }

    function withdraw() public onlyOwner {
        address payable owner = payable(faceitOwner);
        owner.transfer(address(this).balance);
    }

    function contractCurrentBalance() public view returns (uint) {
        return address(this).balance;
    }

    struct Player {
        string nickname;
        uint balance;
        uint rating;
        uint lastTimeClaimed;
        bool created;
        bool participant;
    }

    address public faceitOwner;

    mapping(address => Player) private balances;

    constructor() {
        faceitOwner = msg.sender;
        console.log("Who is calling ctor: %s", msg.sender);
    }

    function participate() public payable onlyRegistredPlayer {
        require(msg.value >= 3750000000000000);
        balances[msg.sender].participant = true;

        emit playerHadParticipate(msg.sender, true);
        console.log("current contract balance: %s", address(this).balance);
    }

    function createPlayerAccount(
        string calldata _nickname,
        uint _rating
    ) external {
        require(!balances[msg.sender].created);

        Player memory newPlayer = Player({
            nickname: _nickname,
            balance: 0,
            rating: _rating,
            lastTimeClaimed: block.timestamp,
            created: true,
            participant: false
        });

        balances[msg.sender] = newPlayer;
        emit playerAccountCreated(
            msg.sender,
            newPlayer.balance,
            newPlayer.lastTimeClaimed,
            newPlayer.created,
            newPlayer.participant
        );
    }

    function getPlayer()
        public
        view
        onlyRegistredPlayer
        returns (Player memory)
    {
        return balances[msg.sender];
    }

    function getBalance() public view onlyRegistredPlayer returns (uint) {
        return balances[msg.sender].balance;
    }

    function correctClaimTime(address _player) public onlyOwner {
        require(balances[_player].created);
        require(balances[_player].participant);

        balances[_player].lastTimeClaimed -= 7 days;
    }

    function balanceAccrual(
        uint _rating
    ) public onlyRegistredPlayer onlyParticipant {
        require(
            block.timestamp - balances[msg.sender].lastTimeClaimed >= DURATION,
            "it hasn't been a week yet"
        );
        uint value = getETHforRating(_rating);
        require(value > 0, "zero gain");
        require(
            address(this).balance >= value,
            "not enough currency on contract"
        );
        balances[msg.sender].balance += value;
        balances[msg.sender].lastTimeClaimed = block.timestamp;
        balances[msg.sender].rating = _rating;
        console.log(
            "account %s --- Balance: %s with rating %s",
            msg.sender,
            balances[msg.sender].balance,
            _rating
        );
        address payable _to = payable(msg.sender);
        _to.transfer(value);
        emit balanceChanged(
            msg.sender,
            balances[msg.sender].balance,
            value,
            block.timestamp
        );
    }

    function getTimeForNextClaim()
        public
        view
        onlyRegistredPlayer
        onlyParticipant
        returns (uint)
    {
        return block.timestamp - balances[msg.sender].lastTimeClaimed;
    }

    function getETHforRating(uint _rating) private returns (uint) {
        if (_rating <= balances[msg.sender].rating) {
            return 0;
        } else {
            return (_rating - balances[msg.sender].rating);
        }
    }
}
