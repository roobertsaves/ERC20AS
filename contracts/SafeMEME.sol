// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract SafeMEME is ERC20 {
    bool private paused;
    address private currentOwner;

    mapping(bytes32 => bool) private perBlock;
    mapping(address => bool) private exceptions;

    constructor() ERC20("SafeMEME", "sMEME") {
        currentOwner = msg.sender;
        paused = false;
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    /**
    * @dev Most minimalistic onlyOwner version
    * `onlyOwner` modifier makes functions callable only for current owner.
    */

    modifier onlyOwner {
        require(msg.sender == currentOwner, "ERC20: Not allowed.");
        _;
    }

    /**
    * @dev Set a new owner for this contract
    * `setOwner(address)` function sets a new owner or this contract.
    * only callable by current owner; newOwner can't be zero address
    */
    
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "ERC20: Zero address can't be owner");
        currentOwner = newOwner;
    }

    /**
    * @dev Returns current owner of this contract
    */

    function owner() public view returns(address) {
        return currentOwner;
    }

    /**
    * @dev Anti sandwich modifier
    * `onlyOncePerBlock` modifier makes transfer/transferFrom functions only callable
    *       -- once per block per address
    *       -- if _from is not an exception
    */

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

    /**
    * @dev Add exceptional addresses
    * `addException(address[])` funciton allows owner to add addresses being excluded from the onlyOncePerBlock restriction
    */

    function addExceptions(address[] memory _exceptions) public onlyOwner {
        for (uint i = 0; i < _exceptions.length; i++) {
            exceptions[_exceptions[i]] = true;
        }
    }

    /**
    * @dev Most minimalistic version of pausable contract
    * `whenNotPauseed` modifier makes transfer/transferFrom functions only callable when contract not paused.
    */

    modifier whenNotPaused {
        require(!paused, "ERC20: Not when paused!");
        _;
    }

    /**
    * @dev Set a new pause status
    * `setStatus(bool)` function sets a paused either to false/true.
    * only callable by current owner;
    */

    function setStatus(bool pause) public onlyOwner {
        paused = pause;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused onlyOncePerBlock(from,to) override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
