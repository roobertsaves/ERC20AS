# ERC20AntiSandwich
## Never get jared again.

This project demonstrates a basic ERC20 token use case. It comes with a special modifier for the transfer and transferFrom functionality. The modifier "onlyOncePerBlock(address)" will make a token sender only be able to send a transfer transaction once per block. A sandwich (front- & backrun within one block) isn't possible anymore. Although a single frontrun or a backrun will still be possible.

### Magic modifier
```solidity
mapping(bytes32 => bool) private perBlock;
...
...
...
modifier onlyOncePerBlock(address _from) {
    bytes32 key = keccak256(abi.encodePacked(block.number, _from));
    require(!perBlock[key], "ERC20: Only one transfer per block per address");
    perBlock[key] = true;
    _;
}
...
...
...
function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused onlyOncePerBlock(from) override {
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