//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


contract P2PTest {


  //Global Variables
  Borrower[] public borrowers; //An array that will hold all of our borrowers 
  Investor[] public investors; //An array that will hold all of our investors
  Loan[] public loans; //An array that will hold all of our loans 
  LoanContract[] public loancontracts; 
  uint totalNumBorrowers; //Keep track of the total number of borrowers we have 
  uint totalNumInvestors; //Keep track of the total number of investors that we have
  uint totalNumLoans;  //Keep track of the total number of loans that are created 
  uint borrowerIdCounter; //Keep track of the borrowerIds --> increment everytime we add a new borrower
  uint investorIdCounter; //Helps create the investorId so that we can keep track of them
  uint loanIdCounter; //Dynamically assign id in the loan Struct
  uint loanContractIdCounter; 



  //Mappings 
  mapping (uint => address) public borrowerToOwner; //Lookup borrower address from their id 
  mapping(address => uint) public BorrowerAddress2Id; //Lookup borrower id based on their address
  mapping (address => Borrower) public borrower; //take an address and get the Borrower struct
  mapping(address => uint[]) public loansBorrowerHasCreated; //address to list of loan_ids the borrower has created
  mapping (uint => address) public investorToOwner; // take an id from our investors arrray and get the address of the investor
  mapping (address => uint) public InvestorAddress2Id; //Lookup investor id based on their address
  mapping (address => Investor) public investor; //take an address and get the investor struct
  mapping (uint => address) public loanToOwner; //Lookup loan owner address (the borrower who created the loan) from a loanId
  mapping(address => uint) public LoanAddrerss2Id; //Lookup loan id from an address
  mapping(address => Loan) public loan; //take an id and look at the loan struct details
  mapping(uint => address[]) public investorsOnLoan; //search loan id and see all investors on it
  mapping(uint => Investor[]) public investorsOnLoan2; 
  mapping(address => uint[]) public loansOnInvestor; //search investor and see all loans they have funded
  mapping(uint => uint[]) public loanIdToFundingAmounts;//Take a loan id and get the payment amounts (how much investors put in/funded)
  mapping (address => uint) public investorNumInvestments; //take an investor address and get the number of loans they are funding
  mapping(uint => address[]) public borrowersOnLoan; 
  mapping(uint => LoanContract[]) public loanContractsOnLoanId; //Query a loan Id and see all loan contracts on it 


  //events 
  event newBorrower(uint borrowerId, string firstName, string lastName, uint accountBalance); //Capability to listen to emission of new borrrower 
  event newInvestor(uint investorId, string firstName, string lastName, uint accountBalance); 
  event newLoan(uint loanId, uint totalAmount, uint interestRate, uint loanDuration); 
  
  //Borrower Struct 
  struct Borrower { 
    address borrowerPublicKey;
    string firstName; 
    string lastName; 
    uint accountBalance; 
    uint numLoans; 
    uint borrowerId; 
    bool EXISTS; 
  }

  //Investor Struct 
  struct Investor {
    address investorPublicKey; 
    string firstName; 
    string lastName; 
    uint accountBalance; 
    uint numInvestments; 
    uint investorId; 
    bool EXISTS; 
  }

  //Create a new Loan
  struct Loan { //ToDo: Add 2 arrrrays to the loan to track the investors on it and the amount they funded 
    string shortDescription;
    string loanDescription;
    string tag;
    string startDate; 
    uint loanId; 
    uint loanDuration;  
    uint totalAmount; 
    uint amountFunded; 
    uint interestRate; 
    uint numFunders;
    bool EXISTS; 
    bool fundedStatus; //false not funded, true is fully funded 
  }

  struct LoanContract {
    address borrowerPublicKey; 
    address investorPublicKey; 
    uint originalInvestmentAmount; 
    uint originalInvestmentAmountInvestor;
    uint currentPaybackAmount; 
    uint interestRate; 
    uint loanTerm; 
    uint loanId; 
    uint loanContractId; 
    string loanStartDate; 
    string shortDescription; 
    string loanDescription;
  }

  //Create a new borrower 
  function createBorrower(string memory _firstName, string memory _lastName, uint _accountBalance) public {
    require(isBorrower(msg.sender) == false); //you can only have one borrower profile so we check if the msg.sender has already created one
    //If the borrower msg.sender does not exist then we create it :)
    Borrower memory b  = Borrower(msg.sender, _firstName, _lastName, _accountBalance, 0, borrowerIdCounter, true);
    uint id = borrowers.push(b) - 1;
    borrowerToOwner[borrowerIdCounter] = msg.sender; 
    BorrowerAddress2Id[msg.sender] = borrowerIdCounter; 
    borrower[msg.sender] = b;
    totalNumBorrowers++; 
    borrowerIdCounter++; 
    emit newBorrower(b.borrowerId, b.firstName, b.lastName, b.accountBalance); //Emit a new borrower everytime one is created 
  }

  //Create a new Investor 
  function createInvestor(string memory _firstName, string memory _lastName, uint _accountBalance) public {
    require(isInvestor(msg.sender) == false); //You can only have one investor profile 
    //If the investor does not exist we will create them :)
    Investor memory i = Investor(msg.sender, _firstName, _lastName, _accountBalance, 0, investorIdCounter, true);
    uint id = investors.push(i) - 1;
    investorToOwner[investorIdCounter] = msg.sender;
    InvestorAddress2Id[msg.sender] = investorIdCounter;
    investor[msg.sender] = i;
    totalNumInvestors++;  
    investorIdCounter++; 
    emit newInvestor(i.investorId, i.firstName, i.lastName, i.accountBalance);
  }

  function createLoan(string memory _shortDescription, string memory _loanDetails, string memory _tag, string memory _startDate, uint _loanDuration, uint _totalAmount, uint _interestRate) public {
    //Require a Borrower profile to create a loan then push it to our loans arrat
    require(isBorrower(msg.sender)); //Only a borrower profile can create a loan
    Loan memory l = Loan(_shortDescription, _loanDetails, _tag, _startDate, loanIdCounter, _loanDuration, _totalAmount, 0, _interestRate, 0, true,false); //default to 0 for amount funded
    loans.push(l) - 1;
    loanToOwner[loanIdCounter] = msg.sender; //id of loan to address of the borrower addrress who created the loan
    LoanAddrerss2Id[msg.sender] = loanIdCounter;  
    loan[msg.sender] = l; //the borrower who created the loan
    loansBorrowerHasCreated[msg.sender].push(loanIdCounter); 
    totalNumLoans++; 
    loanIdCounter++; 
    borrowers[BorrowerAddress2Id[msg.sender]].numLoans++; 
    borrower[msg.sender].numLoans++;
    emit newLoan(l.loanId, l.totalAmount, l.interestRate, l.loanDuration);
  }

  function fundLoan(uint _loanId, uint _fundingAmount) external {
    require(isLoan(_loanId)); //check if loan exists 
    require(isInvestor(msg.sender)); //check if msg.sender is an investor account 
    require(investor[msg.sender].accountBalance >= _fundingAmount); //Make sure investor has enough money for funding the loan
    require (_fundingAmount <= (loans[_loanId].totalAmount - loans[_loanId].amountFunded )); //make sure amount <= (loan amount - amount funded)
    require(loan[loanToOwner[_loanId]].fundedStatus == false); //make sure the loan is not already funded 

    loan[loanToOwner[_loanId]].amountFunded += _fundingAmount; // increment the amount the loan has been funded
    loans[_loanId].amountFunded += _fundingAmount; //change the funding amount in the loans structure
    loan[loanToOwner[_loanId]].numFunders += 1; //increment how many investors are on this loan
    loans[_loanId].numFunders += 1; //increment how many investors are on this loan
    if (loan[loanToOwner[_loanId]].amountFunded == loans[_loanId].totalAmount) {
      loan[loanToOwner[_loanId]].fundedStatus = true; // if the loan is fully funded change the status to true
      loans[_loanId].fundedStatus = true; //if the loan is fully funded change the status to true
    }
    investorsOnLoan[_loanId].push(msg.sender); //add the investor to the list -- for loan can see all investors
    investorsOnLoan2[_loanId].push(investor[msg.sender]);
    loansOnInvestor[msg.sender].push(_loanId); //Search investor and see all of their loans
    
    investorNumInvestments[msg.sender]++; //Increment the number of loans that have been funded for the investor
    investor[msg.sender].numInvestments++; //incrementt the number of investments for the investor
    investors[investor[msg.sender].investorId].numInvestments++; //incrementt the number of investments for the investor

    //Reduce the account Balance by the funding for the investor in both arrays 
    investor[msg.sender].accountBalance -= _fundingAmount; 
    investors[investor[msg.sender].investorId].accountBalance -= _fundingAmount; 
    
    //Increment Borrower account balance by the funding in both global arrays 
    borrower[loanToOwner[_loanId]].accountBalance += _fundingAmount;
    borrowers[borrower[loanToOwner[_loanId]].borrowerId].accountBalance += _fundingAmount; 
    borrowersOnLoan[_loanId].push(borrower[loanToOwner[_loanId]].borrowerPublicKey);

    loanIdToFundingAmounts[_loanId].push(_fundingAmount); //keep track of funding amounts on loan


    //Create the loan contract 
    uint _paybackwithInterest = interestCalc(2,_fundingAmount,loans[_loanId].interestRate);
    LoanContract memory lc = LoanContract(borrower[loanToOwner[_loanId]].borrowerPublicKey, msg.sender, _fundingAmount, _paybackwithInterest, _paybackwithInterest, loans[_loanId].interestRate, loans[_loanId].loanDuration, _loanId,loanContractIdCounter, loans[_loanId].startDate,loans[_loanId].shortDescription, loans[_loanId].loanDescription);
    uint id = loancontracts.push(lc) - 1;
    loanContractsOnLoanId[_loanId].push(lc);
    loanContractIdCounter++; 


    /* 
    address borrowerPublicKey; 
    address investorPublicKey; 
    uint originalInvestmentAmount; 
    uint currentPaybackAmount; 
    uint interestRate; 
    uint loanTerm; 
    uint loanId; 
    uint loanContractId;

    */
  }


  /////// HANDLE FUNDING
  function changeFundingAmounts(uint _loanId,uint _investorId, uint _fundingAmount) public {
    //We need to change the funding amount when a loan is paid back
    uint[]  memory _investorIds = getLoanInvestorsIds(_loanId);
    //uint[] memory _fundingAmounts = getFundingAmounts(_loanId); 
    uint counter = 0;  
    for (uint i=1; i<=_investorIds.length; i++) {
      if (_investorIds[counter] == _investorId) {
        if (_fundingAmount >= loanIdToFundingAmounts[_loanId][counter]) {
          loanIdToFundingAmounts[_loanId][counter] = 0; 
        } else {
        loanIdToFundingAmounts[_loanId][counter] -= _fundingAmount; 
        }
      }
      counter++; 
    }
  }

    function getLoanInvestorsIds(uint _loanId) public view returns (uint[] memory) {
    //Pass in a loanId and see all investor addresses that are on it 
    uint[] memory _investorsOnThisLoan = new uint[](investorsOnLoan2[_loanId].length);
    uint counter = 0; 
    for (uint i= 1;  i<= investorsOnLoan2[_loanId].length; i++) {
      _investorsOnThisLoan[counter]= investorsOnLoan2[_loanId][counter].investorId; 
      counter++;  

    }
    return _investorsOnThisLoan; 
  }

  function _paybackInvestor(uint _investorId, uint _loanId, uint paybackAmount) public  {
    //address _investorAddress = investorToOwner[_investorId]; 
    //require(isBorrower(msg.sender)); //check if loan exists 
    require(isLoan(_loanId));

    uint borrower_balance = borrower[msg.sender].accountBalance;
    require(borrower_balance >= paybackAmount);  
    
    investors[_investorId].accountBalance += paybackAmount;
    investor[investorToOwner[_investorId]].accountBalance += paybackAmount;

    borrower[loanToOwner[_loanId]].accountBalance -= paybackAmount; 
    borrowers[borrower[loanToOwner[_loanId]].borrowerId].accountBalance -= paybackAmount;

    changeFundingAmounts(_loanId,_investorId, paybackAmount); //change how much the investor is owed based on the paybackAmount from the borrower

    //Go to the loan contract (loancontracts) and find the investor and change their payback amount as well
    LoanContract[] memory lcs = loanContractsOnLoanId[_loanId]; 
    uint counter = 0;
    for (uint i=1; i<=lcs.length; i++) {
      if(InvestorAddress2Id[lcs[counter].investorPublicKey] == _investorId) {
        if (paybackAmount >= loanContractsOnLoanId[_loanId][counter].currentPaybackAmount) {
          loanContractsOnLoanId[_loanId][counter].currentPaybackAmount = 0; 
          loancontracts[loanContractsOnLoanId[_loanId][counter].loanContractId].currentPaybackAmount = 0; 
          } 
        else {
          loanContractsOnLoanId[_loanId][counter].currentPaybackAmount -= paybackAmount; 
          loancontracts[loanContractsOnLoanId[_loanId][counter].loanContractId].currentPaybackAmount -= paybackAmount; 
      }
        counter++; 
      } else {
        counter++; 
      }
    }

    }

    function getFundingAmounts(uint _loanId) public view returns (uint[] memory) {
    uint[] memory loan_amounts = new uint[] (loanIdToFundingAmounts[_loanId].length);
    uint counter = 0; 
    for (uint i= 1;  i<= loanIdToFundingAmounts[_loanId].length; i++) {
      loan_amounts[counter]= loanIdToFundingAmounts[_loanId][counter]; 
      counter++;  
    }
    return loan_amounts; 
  }



  
  /*function getBorrowerNames() public view returns (string[] memory) {
    //Pass in a loanId and see all investor addresses that are on it 
    string[] memory borrrowerNames = new string[](borrowers.length); 
    uint counter = 0; 
    for (uint i= 1;  i<= borrowers.length; i++) {
      borrrowerNames[counter]= borrowers[counter].firstName; 
      counter++;  
    }
    return borrrowerNames; 
  } */

  function getTotalNumBorrowers() public view returns (uint) {
    //Allows us to see how many borrowers we have --> we can loop over this range to get all borrower information
    return totalNumBorrowers;
  }

  function getTotalNumInvestors() public view returns (uint) { 
    //Allows us to see how many investors we have --> we can loop over this range to get all borrower information
    return totalNumInvestors; 
  }

  function getTotalNumLoans() public view returns (uint) { 
    return totalNumLoans; 
  }

  function getLoansBorrowerHasCrerated(address _address) public view returns(uint[] memory) {
    return loansBorrowerHasCreated[_address];
  }

  function getLoanIdsByInvestor(address _address) public view returns(uint[] memory) {
    return loansOnInvestor[_address];
  }

  function getInvestorsByLoanId(uint _loanId) public view returns(address[] memory) {
    return investorsOnLoan[_loanId];
  }

  function getFundingAmountsByLoanId(uint _loanId) public view returns(uint[] memory) {
    return loanIdToFundingAmounts[_loanId];
  }

  function getBorrowersOnLoan(uint _loanId) public view returns(address[] memory) {
    return borrowersOnLoan[_loanId];
  }


  function interestCalc(uint decimals, uint totalValue, uint percentage) public view returns (uint) { 
    totalValue = totalValue * 10**decimals;
    uint AddValue = totalValue * percentage;
    AddValue = AddValue / 100;
    totalValue += AddValue;
    return totalValue = totalValue / 10**decimals;
  }

  /*function getAllLoanIds() public view returns(uint[] memory ){ 
    uint[] memory loanIds = new uint[](loans.length);
    uint counter = 0; 
    for (uint i= 1;  i<= loans.length; i++) {
      loanIds.push(counter);
      counter++; 

    }
    return loanIds; 
  } */

  function getAllLoanIds() public view returns (uint[] memory) {
    uint[] memory allids = new uint[] (loans.length);
    uint counter = 0; 
    for (uint i= 1;  i<= loans.length; i++) {
      allids[counter]= loans[counter].loanId; 
      counter++;  
    }
    return allids; 
  }

  function getLoanContractIdsFromLoanId(uint _loanId) public view returns (uint[] memory) {
    //This will get us an array of loan contracts on an loan id 
    LoanContract[] memory lcs = loanContractsOnLoanId[_loanId];
    uint counter = 0;
    uint[] memory ls_arr = new uint[] (lcs.length); 
    for (uint i=1; i<= lcs.length; i++) {
      ls_arr[counter] = lcs[counter].loanContractId; 
      counter++; 
    }
    return ls_arr; 
  }

  function getLoanContractsInvestorHas(address _address) public view returns (uint[] memory) {
    uint counter = 0; 
    //uint numInvestments = investor[_address].numInvestments; 
    uint[] memory investorcontracts = new uint[](investorNumInvestments[_address]); 
    for (uint i=0; i < loancontracts.length; i++) {
      if (loancontracts[i].investorPublicKey == _address) {
        investorcontracts[counter] = loancontracts[i].loanContractId; 
        counter++; 
      } 
    }
    return investorcontracts;
  }

  
  function isBorrower(address account) public view returns (bool) {return borrower[account].EXISTS;}
  function isInvestor(address account) public view returns (bool) {return investor[account].EXISTS;}
  function isLoan(uint _id) public view returns (bool) {return loan[loanToOwner[_id]].EXISTS;}




}


