// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "solidity-docgen";

/// @title Player account contract
/// @notice Player account contract that represent basin functionality of faceit webwallet
/// @dev test coverage over 80%
contract Account {
    uint constant DURATION = 7 days;

    event Received(address, uint, uint);

    /// @notice storing player info [wallet address, balance, last time claimed points, bool state accountCreated, bool state Participant]
    /// @dev Used for storing player data for frontend
    event playerAccountCreated(
        address _player,
        uint _balance,
        uint _lastTimeClaimed,
        bool _created,
        bool _participant
    );

    /// @notice storing data abount currenct player gains from our service
    /// @dev Used for storing player data for frontend
    event balanceChanged(
        address indexed _player,
        uint _newBalance,
        uint _gain,
        uint _timestamp
    );

    /// @notice Used for storing player participant state for frontend
    /// @dev Used for storing player data for frontend
    event playerHadParticipate(address _player, bool _participant);

    receive() external payable {
        emit Received(msg.sender, msg.value, block.timestamp);
        console.log("received: %s", address(this).balance);
    }

    fallback() external payable {}

    /// @dev only owner modifier
    modifier onlyOwner() {
        require(msg.sender == faceitOwner, "you are not a owner!");
        _;
    }

    /// @dev only registred modifier
    modifier onlyRegistredPlayer() {
        require(balances[msg.sender].created);
        _;
    }

    /// @dev only participant modifier
    modifier onlyParticipant() {
        require(balances[msg.sender].participant);
        _;
    }

    function withdraw() public onlyOwner {
        address payable owner = payable(faceitOwner);
        owner.transfer(address(this).balance);
    }

    /// @notice Function to check current balance on contract
    /// @param void
    /// @return balance on current contract
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

    /// @notice payble access to participate, only for registered users
    /// @dev set inner state of player to be participant
    /// @param void
    /// @return void
    function participate() public payable onlyRegistredPlayer {
        require(
            msg.value >= 3750000000000000,
            "not enough currency to participate"
        );
        balances[msg.sender].participant = true;

        emit playerHadParticipate(msg.sender, true);
        console.log("current contract balance: %s", address(this).balance);
    }

    /// @notice create player in blockchaim storage (if one isn't exist yet)
    /// @dev add new struct to mapping (map to address)
    /// @param _nickname player nickname
    /// @param _rating player rating
    /// @return void
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

    /// @notice view player data bassed on connected wallet of created user in mapping
    /// @dev public view function to player data for connected wallet
    /// @return player player DTO
    function getPlayer()
        public
        view
        onlyRegistredPlayer
        returns (Player memory)
    {
        return balances[msg.sender];
    }

    /// @notice view player current balance on gains in our app
    /// @dev public view function to player balance
    /// @return balance current player overall earnings
    function getBalance() public view onlyRegistredPlayer returns (uint) {
        return balances[msg.sender].balance;
    }

    /// @notice funtion for owner usage
    /// @dev owner function to correct some player claim time
    /// @return void
    function correctClaimTime(address _player) public onlyOwner {
        require(balances[_player].created);
        require(balances[_player].participant);

        balances[_player].lastTimeClaimed -= 7 days;
    }

    /// @notice core function that accrual balance on player waller based on his rating increase
    /// @dev change claim date to now and rating, doing transaction on player wallet
    /// @param _rating player new rating
    /// @return void
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

    /// @notice function to frontend usage to estimate time to next claim
    /// @dev now - last time claimed
    /// @return void
    function getTimeForNextClaim()
        public
        view
        onlyRegistredPlayer
        onlyParticipant
        returns (uint)
    {
        return block.timestamp - balances[msg.sender].lastTimeClaimed;
    }

    /// @notice function to estimate gains based on rating increase
    /// @param _rating player new rating
    /// @return gain player earnings value
    function getETHforRating(uint _rating) private returns (uint) {
        if (_rating <= balances[msg.sender].rating) {
            return 0;
        } else {
            return (_rating - balances[msg.sender].rating);
        }
    }
}
