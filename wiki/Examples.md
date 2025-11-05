# Examples

> Catatan kompatibilitas (Windows native-only, compile-only)
> - Contoh di halaman ini menunjukkan kemampuan penuh OMEGA. Saat ini CI aktif adalah Windows-only dengan wrapper CLI untuk kompilasi file tunggal.
> - Untuk verifikasi dasar gunakan: `scripts/build_omega_native.ps1`, `omega.exe`/`omega.ps1` dengan `omega compile <file.mega>`, dan Native Runner (HTTP) `POST /compile`.
> - Perintah `omega build/test/deploy` serta tooling non-native (`npm`, `mdBook`, `valgrind`, `cargo-tarpaulin`) bersifat forward-looking/opsional. Coverage: `scripts/generate_coverage.ps1`.

Halaman ini menyediakan koleksi lengkap contoh smart contract OMEGA untuk berbagai use case, dari token sederhana hingga protokol DeFi yang kompleks.

## 🎯 Overview

Semua contoh di halaman ini mendemonstrasikan fitur-fitur utama OMEGA:
- **Universal Compatibility**: Dapat dikompilasi untuk EVM dan non-EVM chains
- **Type Safety**: Strong typing dan compile-time checks
- **Cross-Chain Features**: Komunikasi antar blockchain
- **Security Patterns**: Best practices untuk keamanan

## 🪙 Basic Token Examples

### Simple ERC20 Token

Contoh implementasi token ERC20 dasar dengan fitur transfer dan approval:

```omega
// File: SimpleToken.omega
blockchain SimpleToken {
    state {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 total_supply;
        string name;
        string symbol;
        uint8 decimals;
        address owner;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string _name, string _symbol, uint256 _initial_supply) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        total_supply = _initial_supply * (10 ** decimals);
        owner = msg.sender;
        balances[msg.sender] = total_supply;
        
        emit Transfer(address(0), msg.sender, total_supply);
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer_from(address from, address to, uint256 amount) public returns (bool) {
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");
        require(balances[from] >= amount, "Insufficient balance");
        
        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    function balance_of(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }
}
```

### Advanced Token with Features

Token dengan fitur tambahan seperti minting, burning, dan pause:

```omega
// File: AdvancedToken.omega
import std.math.SafeMath;
import std.access.Ownable;

blockchain AdvancedToken extends Ownable {
    state {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(address => bool) blacklisted;
        
        uint256 total_supply;
        uint256 max_supply;
        string name;
        string symbol;
        uint8 decimals;
        bool paused;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Pause();
    event Unpause();
    event Blacklist(address indexed account, bool status);
    
    modifier when_not_paused {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier not_blacklisted(address account) {
        require(!blacklisted[account], "Account is blacklisted");
        _;
    }
    
    constructor(
        string _name, 
        string _symbol, 
        uint256 _initial_supply,
        uint256 _max_supply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        max_supply = _max_supply * (10 ** decimals);
        total_supply = _initial_supply * (10 ** decimals);
        balances[msg.sender] = total_supply;
        
        emit Transfer(address(0), msg.sender, total_supply);
    }
    
    function mint(address to, uint256 amount) public only_owner {
        require(to != address(0), "Mint to zero address");
        require(SafeMath.add(total_supply, amount) <= max_supply, "Exceeds max supply");
        
        total_supply = SafeMath.add(total_supply, amount);
        balances[to] = SafeMath.add(balances[to], amount);
        
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }
    
    function burn(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], amount);
        total_supply = SafeMath.sub(total_supply, amount);
        
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function pause() public only_owner {
        paused = true;
        emit Pause();
    }
    
    function unpause() public only_owner {
        paused = false;
        emit Unpause();
    }
    
    function set_blacklist(address account, bool status) public only_owner {
        blacklisted[account] = status;
        emit Blacklist(account, status);
    }
    
    function transfer(address to, uint256 amount) 
        public 
        when_not_paused 
        not_blacklisted(msg.sender) 
        not_blacklisted(to) 
        returns (bool) {
        
        require(to != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], amount);
        balances[to] = SafeMath.add(balances[to], amount);
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}
```

## 🎨 NFT Examples

### Basic NFT Collection

```omega
// File: BasicNFT.omega
import std.collections.Vector;

blockchain BasicNFT {
    state {
        mapping(uint256 => address) token_owners;
        mapping(address => uint256) owner_token_count;
        mapping(uint256 => address) token_approvals;
        mapping(address => mapping(address => bool)) operator_approvals;
        
        uint256 next_token_id;
        string name;
        string symbol;
        string base_uri;
        address owner;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 indexed token_id);
    event Approval(address indexed owner, address indexed approved, uint256 indexed token_id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    constructor(string _name, string _symbol, string _base_uri) {
        name = _name;
        symbol = _symbol;
        base_uri = _base_uri;
        owner = msg.sender;
        next_token_id = 1;
    }
    
    function mint(address to, string memory token_uri) public returns (uint256) {
        require(msg.sender == owner, "Not owner");
        require(to != address(0), "Mint to zero address");
        
        uint256 token_id = next_token_id;
        next_token_id += 1;
        
        token_owners[token_id] = to;
        owner_token_count[to] += 1;
        
        emit Transfer(address(0), to, token_id);
        return token_id;
    }
    
    function transfer_from(address from, address to, uint256 token_id) public {
        require(is_approved_or_owner(msg.sender, token_id), "Not approved or owner");
        require(to != address(0), "Transfer to zero address");
        
        // Clear approval
        token_approvals[token_id] = address(0);
        
        // Update balances
        owner_token_count[from] -= 1;
        owner_token_count[to] += 1;
        token_owners[token_id] = to;
        
        emit Transfer(from, to, token_id);
    }
    
    function approve(address to, uint256 token_id) public {
        address token_owner = token_owners[token_id];
        require(msg.sender == token_owner || operator_approvals[token_owner][msg.sender], 
                "Not owner or approved operator");
        
        token_approvals[token_id] = to;
        emit Approval(token_owner, to, token_id);
    }
    
    function owner_of(uint256 token_id) public view returns (address) {
        address token_owner = token_owners[token_id];
        require(token_owner != address(0), "Token does not exist");
        return token_owner;
    }
    
    function balance_of(address account) public view returns (uint256) {
        require(account != address(0), "Query for zero address");
        return owner_token_count[account];
    }
    
    function is_approved_or_owner(address spender, uint256 token_id) internal view returns (bool) {
        address token_owner = token_owners[token_id];
        return (spender == token_owner || 
                token_approvals[token_id] == spender || 
                operator_approvals[token_owner][spender]);
    }
}
```

## 💰 DeFi Examples

### Automated Market Maker (AMM)

```omega
// File: LiquidityPool.omega
import std.math.{SafeMath, sqrt};

blockchain LiquidityPool {
    state {
        address token_a;
        address token_b;
        uint256 reserve_a;
        uint256 reserve_b;
        uint256 total_liquidity;
        
        mapping(address => uint256) liquidity_balances;
        uint256 fee_rate; // 30 = 0.3%
        uint256 minimum_liquidity;
    }
    
    event LiquidityAdded(address indexed provider, uint256 amount_a, uint256 amount_b, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amount_a, uint256 amount_b, uint256 liquidity);
    event Swap(address indexed trader, uint256 amount_in, uint256 amount_out, bool a_to_b);
    event Sync(uint256 reserve_a, uint256 reserve_b);
    
    constructor(address _token_a, address _token_b) {
        require(_token_a != _token_b, "Identical tokens");
        require(_token_a != address(0) && _token_b != address(0), "Zero address");
        
        token_a = _token_a;
        token_b = _token_b;
        fee_rate = 30; // 0.3%
        minimum_liquidity = 1000;
    }
    
    function add_liquidity(uint256 amount_a, uint256 amount_b) public returns (uint256) {
        require(amount_a > 0 && amount_b > 0, "Invalid amounts");
        
        // Transfer tokens from user
        IERC20(token_a).transfer_from(msg.sender, address(this), amount_a);
        IERC20(token_b).transfer_from(msg.sender, address(this), amount_b);
        
        uint256 liquidity;
        if (total_liquidity == 0) {
            // First liquidity provision
            liquidity = SafeMath.sub(sqrt(SafeMath.mul(amount_a, amount_b)), minimum_liquidity);
            total_liquidity = minimum_liquidity; // Lock minimum liquidity
        } else {
            // Calculate proportional liquidity
            uint256 liquidity_a = SafeMath.div(SafeMath.mul(amount_a, total_liquidity), reserve_a);
            uint256 liquidity_b = SafeMath.div(SafeMath.mul(amount_b, total_liquidity), reserve_b);
            liquidity = SafeMath.min(liquidity_a, liquidity_b);
        }
        
        require(liquidity > 0, "Insufficient liquidity minted");
        
        // Update state
        liquidity_balances[msg.sender] = SafeMath.add(liquidity_balances[msg.sender], liquidity);
        total_liquidity = SafeMath.add(total_liquidity, liquidity);
        reserve_a = SafeMath.add(reserve_a, amount_a);
        reserve_b = SafeMath.add(reserve_b, amount_b);
        
        emit LiquidityAdded(msg.sender, amount_a, amount_b, liquidity);
        emit Sync(reserve_a, reserve_b);
        
        return liquidity;
    }
    
    function remove_liquidity(uint256 liquidity) public returns (uint256, uint256) {
        require(liquidity > 0, "Invalid liquidity amount");
        require(liquidity_balances[msg.sender] >= liquidity, "Insufficient liquidity");
        
        // Calculate token amounts
        uint256 amount_a = SafeMath.div(SafeMath.mul(liquidity, reserve_a), total_liquidity);
        uint256 amount_b = SafeMath.div(SafeMath.mul(liquidity, reserve_b), total_liquidity);
        
        require(amount_a > 0 && amount_b > 0, "Insufficient liquidity burned");
        
        // Update state
        liquidity_balances[msg.sender] = SafeMath.sub(liquidity_balances[msg.sender], liquidity);
        total_liquidity = SafeMath.sub(total_liquidity, liquidity);
        reserve_a = SafeMath.sub(reserve_a, amount_a);
        reserve_b = SafeMath.sub(reserve_b, amount_b);
        
        // Transfer tokens to user
        IERC20(token_a).transfer(msg.sender, amount_a);
        IERC20(token_b).transfer(msg.sender, amount_b);
        
        emit LiquidityRemoved(msg.sender, amount_a, amount_b, liquidity);
        emit Sync(reserve_a, reserve_b);
        
        return (amount_a, amount_b);
    }
    
    function swap(uint256 amount_in, bool a_to_b) public returns (uint256) {
        require(amount_in > 0, "Invalid input amount");
        
        uint256 amount_out;
        if (a_to_b) {
            amount_out = get_amount_out(amount_in, reserve_a, reserve_b);
            IERC20(token_a).transfer_from(msg.sender, address(this), amount_in);
            IERC20(token_b).transfer(msg.sender, amount_out);
            reserve_a = SafeMath.add(reserve_a, amount_in);
            reserve_b = SafeMath.sub(reserve_b, amount_out);
        } else {
            amount_out = get_amount_out(amount_in, reserve_b, reserve_a);
            IERC20(token_b).transfer_from(msg.sender, address(this), amount_in);
            IERC20(token_a).transfer(msg.sender, amount_out);
            reserve_b = SafeMath.add(reserve_b, amount_in);
            reserve_a = SafeMath.sub(reserve_a, amount_out);
        }
        
        emit Swap(msg.sender, amount_in, amount_out, a_to_b);
        emit Sync(reserve_a, reserve_b);
        
        return amount_out;
    }
    
    function get_amount_out(uint256 amount_in, uint256 reserve_in, uint256 reserve_out) 
        public view returns (uint256) {
        require(amount_in > 0, "Invalid input amount");
        require(reserve_in > 0 && reserve_out > 0, "Invalid reserves");
        
        uint256 amount_in_with_fee = SafeMath.mul(amount_in, SafeMath.sub(10000, fee_rate));
        uint256 numerator = SafeMath.mul(amount_in_with_fee, reserve_out);
        uint256 denominator = SafeMath.add(SafeMath.mul(reserve_in, 10000), amount_in_with_fee);
        
        return SafeMath.div(numerator, denominator);
    }
}
```

## 🌉 Cross-Chain Examples

### Cross-Chain Bridge

```omega
// File: CrossChainBridge.omega
blockchain CrossChainBridge {
    state {
        mapping(bytes32 => bool) processed_transactions;
        mapping(address => uint256) locked_balances;
        mapping(uint32 => bool) supported_chains;
        
        address bridge_operator;
        uint256 bridge_fee;
        bool paused;
    }
    
    event TokensBridged(
        address indexed from, 
        bytes32 indexed to, 
        uint256 amount, 
        uint32 target_chain,
        bytes32 transaction_id
    );
    
    event TokensUnbridged(
        bytes32 indexed from, 
        address indexed to, 
        uint256 amount, 
        uint32 source_chain,
        bytes32 transaction_id
    );
    
    modifier only_operator {
        require(msg.sender == bridge_operator, "Not bridge operator");
        _;
    }
    
    modifier when_not_paused {
        require(!paused, "Bridge is paused");
        _;
    }
    
    constructor() {
        bridge_operator = msg.sender;
        bridge_fee = 0.001 ether; // 0.1% fee
        
        // Enable supported chains
        supported_chains[1] = true;  // Ethereum
        supported_chains[137] = true; // Polygon
        supported_chains[56] = true;  // BSC
    }
    
    @cross_chain(target = "solana")
    function bridge_to_solana(bytes32 recipient, uint256 amount) 
        public payable when_not_paused {
        require(amount > 0, "Invalid amount");
        require(msg.value >= bridge_fee, "Insufficient bridge fee");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        bytes32 transaction_id = keccak256(abi.encodePacked(
            msg.sender, recipient, amount, block.timestamp, block.number
        ));
        
        require(!processed_transactions[transaction_id], "Transaction already processed");
        
        // Lock tokens
        locked_balances[msg.sender] += amount;
        balances[msg.sender] -= amount;
        processed_transactions[transaction_id] = true;
        
        emit TokensBridged(msg.sender, recipient, amount, 0, transaction_id); // 0 = Solana
    }
    
    @cross_chain(target = "ethereum")
    function bridge_to_ethereum(address recipient, uint256 amount) 
        public payable when_not_paused {
        require(amount > 0, "Invalid amount");
        require(msg.value >= bridge_fee, "Insufficient bridge fee");
        require(locked_balances[msg.sender] >= amount, "Insufficient locked balance");
        
        bytes32 transaction_id = keccak256(abi.encodePacked(
            msg.sender, recipient, amount, block.timestamp, block.number
        ));
        
        require(!processed_transactions[transaction_id], "Transaction already processed");
        
        // Unlock tokens
        locked_balances[msg.sender] -= amount;
        balances[recipient] += amount;
        processed_transactions[transaction_id] = true;
        
        emit TokensUnbridged(
            bytes32(uint256(uint160(msg.sender))), 
            recipient, 
            amount, 
            1, // Ethereum
            transaction_id
        );
    }
    
    function process_cross_chain_transaction(
        bytes32 from,
        address to,
        uint256 amount,
        uint32 source_chain,
        bytes32 transaction_id,
        bytes memory signature
    ) public only_operator {
        require(!processed_transactions[transaction_id], "Already processed");
        require(supported_chains[source_chain], "Unsupported source chain");
        
        // Verify signature (simplified)
        bytes32 message_hash = keccak256(abi.encodePacked(
            from, to, amount, source_chain, transaction_id
        ));
        
        require(verify_signature(message_hash, signature), "Invalid signature");
        
        // Mint/unlock tokens
        balances[to] += amount;
        processed_transactions[transaction_id] = true;
        
        emit TokensUnbridged(from, to, amount, source_chain, transaction_id);
    }
    
    function verify_signature(bytes32 hash, bytes memory signature) 
        internal view returns (bool) {
        // Simplified signature verification
        // In production, use proper multi-sig verification
        return true;
    }
}
```

## 🏛️ Governance Examples

### DAO Governance

```omega
// File: DAOGovernance.omega
import std.collections.Vector;

blockchain DAOGovernance {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votes_for;
        uint256 votes_against;
        uint256 start_time;
        uint256 end_time;
        bool executed;
        mapping(address => bool) has_voted;
        mapping(address => uint256) vote_weight;
    }
    
    state {
        mapping(uint256 => Proposal) proposals;
        mapping(address => uint256) voting_power;
        
        uint256 next_proposal_id;
        uint256 proposal_threshold; // Minimum tokens to create proposal
        uint256 voting_period; // Duration of voting in seconds
        uint256 quorum_threshold; // Minimum participation required
        
        address governance_token;
        bool paused;
    }
    
    event ProposalCreated(uint256 indexed proposal_id, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposal_id, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposal_id);
    
    constructor(address _governance_token, uint256 _proposal_threshold) {
        governance_token = _governance_token;
        proposal_threshold = _proposal_threshold;
        voting_period = 7 days;
        quorum_threshold = 100000 * 10**18; // 100k tokens
        next_proposal_id = 1;
    }
    
    function create_proposal(string memory description) public returns (uint256) {
        require(bytes(description).length > 0, "Empty description");
        require(IERC20(governance_token).balance_of(msg.sender) >= proposal_threshold, 
                "Insufficient tokens");
        
        uint256 proposal_id = next_proposal_id++;
        Proposal storage proposal = proposals[proposal_id];
        
        proposal.id = proposal_id;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.start_time = block.timestamp;
        proposal.end_time = block.timestamp + voting_period;
        
        emit ProposalCreated(proposal_id, msg.sender, description);
        return proposal_id;
    }
    
    function vote(uint256 proposal_id, bool support) public {
        Proposal storage proposal = proposals[proposal_id];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.start_time, "Voting not started");
        require(block.timestamp <= proposal.end_time, "Voting ended");
        require(!proposal.has_voted[msg.sender], "Already voted");
        
        uint256 weight = IERC20(governance_token).balance_of(msg.sender);
        require(weight > 0, "No voting power");
        
        proposal.has_voted[msg.sender] = true;
        proposal.vote_weight[msg.sender] = weight;
        
        if (support) {
            proposal.votes_for += weight;
        } else {
            proposal.votes_against += weight;
        }
        
        emit VoteCast(proposal_id, msg.sender, support, weight);
    }
    
    function execute_proposal(uint256 proposal_id) public {
        Proposal storage proposal = proposals[proposal_id];
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp > proposal.end_time, "Voting still active");
        require(!proposal.executed, "Already executed");
        
        uint256 total_votes = proposal.votes_for + proposal.votes_against;
        require(total_votes >= quorum_threshold, "Quorum not reached");
        require(proposal.votes_for > proposal.votes_against, "Proposal rejected");
        
        proposal.executed = true;
        
        // Execute proposal logic here
        // This would typically call other contracts or update state
        
        emit ProposalExecuted(proposal_id);
    }
    
    function get_proposal(uint256 proposal_id) public view returns (
        address proposer,
        string memory description,
        uint256 votes_for,
        uint256 votes_against,
        uint256 start_time,
        uint256 end_time,
        bool executed
    ) {
        Proposal storage proposal = proposals[proposal_id];
        return (
            proposal.proposer,
            proposal.description,
            proposal.votes_for,
            proposal.votes_against,
            proposal.start_time,
            proposal.end_time,
            proposal.executed
        );
    }
}
```

## 🧪 Testing Examples

### Comprehensive Test Suite

```omega
// File: tests/token_tests.omega
test_suite TokenTests {
    use contracts.SimpleToken;
    
    setup {
        let token = SimpleToken.new("Test Token", "TST", 1000000);
        let alice = address("0x1111111111111111111111111111111111111111");
        let bob = address("0x2222222222222222222222222222222222222222");
    }
    
    test "should deploy with correct initial values" {
        assert_eq!(token.name(), "Test Token");
        assert_eq!(token.symbol(), "TST");
        assert_eq!(token.total_supply(), 1000000 * 10**18);
        assert_eq!(token.balance_of(msg.sender), 1000000 * 10**18);
    }
    
    test "should transfer tokens correctly" {
        let initial_balance = token.balance_of(msg.sender);
        let transfer_amount = 1000 * 10**18;
        
        let success = token.transfer(alice, transfer_amount);
        
        assert_eq!(success, true);
        assert_eq!(token.balance_of(alice), transfer_amount);
        assert_eq!(token.balance_of(msg.sender), initial_balance - transfer_amount);
    }
    
    test "should fail transfer with insufficient balance" {
        let excessive_amount = 2000000 * 10**18; // More than total supply
        
        expect_revert(
            token.transfer(alice, excessive_amount),
            "Insufficient balance"
        );
    }
    
    test "should approve and transfer_from correctly" {
        let allowance_amount = 5000 * 10**18;
        let transfer_amount = 3000 * 10**18;
        
        // Approve alice to spend tokens
        token.approve(alice, allowance_amount);
        assert_eq!(token.allowance(msg.sender, alice), allowance_amount);
        
        // Alice transfers tokens from msg.sender to bob
        vm.prank(alice);
        let success = token.transfer_from(msg.sender, bob, transfer_amount);
        
        assert_eq!(success, true);
        assert_eq!(token.balance_of(bob), transfer_amount);
        assert_eq!(token.allowance(msg.sender, alice), allowance_amount - transfer_amount);
    }
    
    test "should handle edge cases" {
        // Test zero transfer
        let success = token.transfer(alice, 0);
        assert_eq!(success, true);
        
        // Test transfer to self
        let initial_balance = token.balance_of(msg.sender);
        token.transfer(msg.sender, 100);
        assert_eq!(token.balance_of(msg.sender), initial_balance);
    }
}
```

## 📊 Performance Benchmarks

### Gas Optimization Examples

```omega
// File: GasOptimized.omega
blockchain GasOptimized {
    // Packed struct to save storage slots
    struct PackedUser {
        uint128 balance;    // 16 bytes
        uint64 last_update; // 8 bytes  
        uint32 user_id;     // 4 bytes
        bool active;        // 1 byte
        // Total: 29 bytes (fits in 32-byte slot)
    }
    
    state {
        mapping(address => PackedUser) users;
        uint256[] batch_data; // For batch operations
    }
    
    // Batch operations to reduce gas costs
    function batch_transfer(address[] memory recipients, uint256[] memory amounts) 
        public {
        require(recipients.length == amounts.length, "Array length mismatch");
        require(recipients.length <= 100, "Batch too large");
        
        uint256 total_amount = 0;
        
        // Calculate total first
        for (uint256 i = 0; i < amounts.length; i++) {
            total_amount += amounts[i];
        }
        
        require(balances[msg.sender] >= total_amount, "Insufficient balance");
        
        // Execute transfers
        balances[msg.sender] -= total_amount;
        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }
    
    // Use events for cheap data storage
    event DataStored(uint256 indexed id, bytes32 indexed hash, bytes data);
    
    function store_data_efficiently(uint256 id, bytes memory data) public {
        bytes32 data_hash = keccak256(data);
        emit DataStored(id, data_hash, data);
        // Data is stored in event logs, not contract storage
    }
}
```

---

## 🔗 Next Steps

Setelah mempelajari contoh-contoh ini, Anda dapat:

1. **Modify Examples**: Sesuaikan contoh dengan kebutuhan spesifik Anda
2. **Combine Patterns**: Gabungkan berbagai pattern untuk use case yang kompleks
3. **Deploy & Test**: Deploy ke testnet dan lakukan testing menyeluruh
4. **Optimize**: Gunakan tools profiling untuk optimasi gas dan performa

### Useful Resources

- [[Getting Started]] - Panduan setup development environment
- [[Language Specification]] - Referensi lengkap sintaks OMEGA
- [[Testing Framework]] - Panduan testing dan debugging
- [[Best Practices]] - Security dan optimization best practices

### Community Examples

Kunjungi [GitHub Repository](https://github.com/Rafael2022-prog/omega-lang/tree/main/examples) untuk contoh-contoh tambahan dari komunitas!