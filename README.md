<div id="user-content-toc">
  <ul>
    <summary><h1 style="display: inline-block;">ERC20AntiSandwich</h1></summary>
    <summary><h2 style="display: inline-block;">Never get jared again.</h2></summary>
  </ul>
</div>

This project demonstrates a basic ERC20 token use case. It comes with a special modifier for the transfer and transferFrom functionality. The modifier "onlyOncePerBlock(address,address)" will make a token sender only be able to send a transfer transaction once per block. A sandwich (front- & backrun within one block) isn't possible anymore. Although a single frontrun or a backrun will still be possible.

### Magic modifier
```solidity
mapping(bytes32 => bool) private perBlock;
mapping(address => bool) private exceptions;
...
...
...
modifier onlyOncePerBlock(address _from, address _to) {
    if (!exceptions[_from]) {
        bytes32 key = keccak256(abi.encodePacked(block.number, _from));
        require(!perBlock[key], "ERC20: Only one transfer per block per address");
        perBlock[key] = true;
    }
    if (!exceptions[_to]) {
        bytes32 key = keccak256(abi.encodePacked(block.number, _to));
        require(!perBlock[key], "ERC20: Only one transfer per block per address");
        perBlock[key] = true;
    }
    _;
}
...
...
...
function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused onlyOncePerBlock(from,to) override {
    super._beforeTokenTransfer(from, to, amount);
}
```

### Getting started

1. Download NodeJS and install it
2. Open terminal and navigate to the project directory
2. Run ```npm install```

### Deploy SafeMEME (an example ERC20AS token)

1. Open .env file and edit ALCHEMY_KEY to your Alchemy API key
2. Run ```npx hardhat compile``` to compile the contract
3. Run ```npx hardhat test``` to test the contract

### Todo's

- [X] Create a working ERC20 boiler plate
- [ ] Optimize modifier onlyOncePerBlock for gas (currently a transfer costs 103.165)
- [ ] Implement a version without the need of modifying the state (removing mapping exceptions)
