//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.5.0;

contract P2PLending {
  
  //Global Counters for overall stats 
  uint totalNumLoans; 
  uint totalNumBorrowers; 
  uint totalNumInvestors; 
  uint totalNumFullyFundedLoans; 
  uint loanIDCounter; //Dynamically assign id in the loan Struct
  uint borrowerIdCounter; //Dynamically assign id in the borrower Struct
  uint investorIdCounter; //Dynamically assign id in the investor Struct
  uint loanTrackerCounter; 

   //Arrays to hold all of our investors and borrowers and loans
  Investor[] public investors; 
  Borrower[] public borrowers; 
  Loan[] public loans; 
  //LoanTracker[] public loantrackers; 

  //Mappings 
  mapping (address => uint) public borrowerNumLoans; //take a borrowerr address and get the number of loans they have in the marketplace
  mapping (address => uint) public investorNumInvestments; //take an investor address and get the number of loans they are funding
  mapping (uint => address) public borrowerToOwner; //take an id from our borrowers array and get the address of the borrower
  mapping (uint => address) public investorToOwner; // take an id from our investors arrray and get the address of the investor
  mapping (address => Borrower) public borrower; //take an address and get the Borrower struct
  mapping (address => Investor) public investor; //take an address and get the investor struct
  mapping (uint => address) public loanToBorrowerAddress; //take a loan id and get the Borrower address
  mapping(uint => Borrower) public loanToBorrower; 
  mapping (uint => Loan) public loan; //take an id from the loan and get the loan information back
  mapping(uint => Investor[]) public invesorsOnLoan; //search loan id and see all investors on it
  //mapping(uint => uint[]) public investorAmounts; 
  mapping(address => Loan[]) public loansOnInvestor; //search investor and see all loans they have funded
  //Structus for our Objects -- Investor, Borrower, Loan
  mapping(uint => uint[]) public loanIdToFundingAmounts;//Take a loan id and get the payment amounts (how much investors put in/funded)
 
  struct Investor {
    address investorPublicKey; 
    string firstName; 
    string lastName; 
    uint accountBalance; 
    uint numInvestments; 
    uint investorId; 
    bool EXISTS; 
  }

  struct Borrower { 
    address borrowerPublicKey;
    string firstName; 
    string lastName; 
    uint accountBalance; 
    uint numLoans; 
    uint borrowerId; 
    bool EXISTS; 
  }

  struct Loan { //ToDo: Add 2 arrrrays to the loan to track the investors on it and the amount they funded 
    string loanDescription;
    uint loanID; 
    uint loanDuration;  
    uint totalAmount; 
    uint amountFunded; 
    uint interestRate; 
    uint numFunders;
    bool EXISTS; 
    bool fundedStatus; //false not funded, true is fully funded 
    //string[] investorAddresses; 
    //uint[] investorAmounts; 
  }

  /*struct LoanTracker {  //Used to keep track of investors and the amounts on this loan once an investor has contributed
    uint loanTrackerId; 
    uint loanId;   
    address borrowerAddress; 
    uint borrowerId; 
    address[] investorAddresses;
    uint[] investorIds; 
    uint[] investorAmounts; 
  } */



  //Create Borrower, Lender, and Loan
  function createBorrower(string memory _firstName, string memory _lastName, uint _accountBalance) public {
    Borrower memory b  = Borrower(msg.sender, _firstName, _lastName, _accountBalance, 0, borrowerIdCounter, true);
    borrowerIdCounter++; 
    uint id = borrowers.push(b) - 1;
    borrowerToOwner[id] = msg.sender; 
    borrower[msg.sender] = b;
    totalNumBorrowers++; 
  }

  function createInvestor(string memory _firstName, string memory _lastName, uint _accountBalance) public {
    Investor memory i = Investor(msg.sender, _firstName, _lastName, _accountBalance, 0, investorIdCounter, true);
    investorIdCounter++; 
    uint id = investors.push(i) - 1;
    investorToOwner[id] = msg.sender;
    investor[msg.sender] = i;
    totalNumInvestors++;  
  }

   function createLoan(string memory _loanDetails, uint _loanDuration, uint _totalAmount, uint _amountFunded, uint _interestRate) public {
    //require (borrower[msg.sender].EXISTS == true); //Required to be a borrower to create a loan
    //Require a Borrower profile to create a loan then push it to our loans arrat
    require(isBorrower(msg.sender)); 
    Loan memory l = Loan(_loanDetails, loanIDCounter, _loanDuration, _totalAmount, _amountFunded, _interestRate, 0, true,false);
    loanIDCounter++; 
    uint id = loans.push(l) - 1;
    loanToBorrowerAddress[id] = msg.sender; //id of loan to address of the borrower addrress who created the loan
    loanToBorrower[id] = borrower[msg.sender]; 
    borrowerNumLoans[msg.sender]++; //increment the number of loans that the borrower has crreated
    totalNumLoans++; 
    loan[id] = l; 
  }

  /*
  A function to fund the loan. We take in a loan id and an amount to fund. 
  */
  function fundLoan(uint _loanId, uint _fundingAmount) external {
    require(isLoan(_loanId)); //check if loan exists 
    require(isInvestor(msg.sender)); //check if msg.sender is an investor account 
    require(investor[msg.sender].accountBalance >= _fundingAmount); //Make sure investor has enough money for funding the loan
    require (_fundingAmount <= (loan[_loanId].totalAmount - loan[_loanId].amountFunded )); //make sure amount <= (loan amount - amount funded)
    require(loan[_loanId].fundedStatus == false); //make sure the loan is not already funded 
    loan[_loanId].amountFunded += _fundingAmount; // increment the amount the loan has been funded
    loans[_loanId].amountFunded += _fundingAmount; //change the funding amount in the loans structure
    loan[_loanId].numFunders += 1; //increment how many investors are on this loan
    loans[_loanId].numFunders += 1; //increment how many investors are on this loan
    if (loan[_loanId].amountFunded == loan[_loanId].totalAmount) {
      loan[_loanId].fundedStatus = true; // if the loan is fully funded change the status to true
      loans[_loanId].fundedStatus = true; //if the loan is fully funded change the status to true
    }

    invesorsOnLoan[_loanId].push(investor[msg.sender]); //add the investor to the list -- for loan can see all investors
    //investorAmounts[_loanId].push(_fundingAmount); //keep track of how much money the investor has invested in this loan
    loansOnInvestor[msg.sender].push(loan[_loanId]); //Search investor and see all of their loans
    
    investorNumInvestments[msg.sender]++; //Increment the number of loans that have been funded for the investor
    investor[msg.sender].numInvestments++; //incrementt the number of investments for the investor
    investors[investor[msg.sender].investorId].numInvestments++; //incrementt the number of investments for the investor

    //TODO: Make sure tomorrow when we fund a loan that the borrower gets the funding in their account and the investor gets reduction in funding
    //Reduce the account Balance by the funding for the investor in both arrays 
    investor[msg.sender].accountBalance -= _fundingAmount; 
    investors[investor[msg.sender].investorId].accountBalance -= _fundingAmount; 
    //Increment Borrower account balance by the funding in both global arrays 
    borrower[loanToBorrowerAddress[_loanId]].accountBalance += _fundingAmount;
    borrowers[loanToBorrower[_loanId].borrowerId].accountBalance += _fundingAmount; 

    loanIdToFundingAmounts[_loanId].push(_fundingAmount); //keep track of funding amounts on loan

   //Add the details of the funding to the loan tracker 
   /*
   if (loan[_loanId].numFunders <= 1){
     //First time creation of loantracker 
     address[] memory first_address;
     first_address.push(loanToBorrowerAddress[_loanId]); 
     uint[] memory first_investorId; 
     first_investorId.push(investor[msg.sender].investorId); 
     uint[] memory first_investorAmount = [_fundingAmount]; 
     //uint[] memory empty_arr = new uint[];
     LoanTracker lt = LoanTracker(loanTrackerCounter, _loanId, loanToBorrowerAddress[_loanId], loanToBorrower[_loanId].borrowerId, first_address, first_investorId, first_investorAmount); 

     loanTrackerCounter++; 
   } else {

   } */ 
   //if (loan[_loanId].)
   //loanIdToLoanTracker[_loanId] = 
   //loanIdToLoanTracker

  }

  //function getInvestorFundingAmount(uint _loanId, address investorAddress) public view returns (uint) {
    function getInvestorFundingAmount(uint _loanId, uint _investorId) public view returns (uint){
    //address[] memory _loanInvestors = getLoanInvestors(_loanId);
    uint[] memory _loanInvestors = getLoanInvestorsIds(_loanId); 
    uint[] memory _fundingAmounts = getFundingAmounts(_loanId);
    uint counter = 0; 
    for (uint i= 1;  i<= _loanInvestors.length; i++) {
      if (_loanInvestors[counter] == _investorId){ 
        return _fundingAmounts[counter]; 
      }
      counter++;  

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

  function changeFundingAmounts(uint _loanId,uint _investorId, uint _fundingAmount) public {
    //We need to change the funding amount when a loan is paid back
    uint[]  memory _investorIds = getLoanInvestorsIds(_loanId);
    //uint[] memory _fundingAmounts = getFundingAmounts(_loanId); 
    uint counter = 0;  
    for (uint i=1; i<=_investorIds.length; i++) {
      if (_investorIds[counter] == _investorId) {
        if (_fundingAmount >= loanIdToFundingAmounts[_loanId][counter]) {
          //_fundingAmount == loanIdToFundingAmounts[_loanId][counter]; 
          loanIdToFundingAmounts[_loanId][counter] = 0; 
        } else {
        loanIdToFundingAmounts[_loanId][counter] -= _fundingAmount; 
        }
      }
      counter++; 
    }
  }

  function getLoanInvestors(uint _loanId) public view returns (address[] memory) {
    //Pass in a loanId and see all investor addresses that are on it 
    address[] memory _investorsOnThisLoan = new address[](invesorsOnLoan[_loanId].length);
    uint counter = 0; 
    for (uint i= 1;  i<= invesorsOnLoan[_loanId].length; i++) {
      _investorsOnThisLoan[counter]= invesorsOnLoan[_loanId][counter].investorPublicKey; 
      counter++;  

    }
    return _investorsOnThisLoan; 
  }

    function getLoanInvestorsIds(uint _loanId) public view returns (uint[] memory) {
    //Pass in a loanId and see all investor addresses that are on it 
    uint[] memory _investorsOnThisLoan = new uint[](invesorsOnLoan[_loanId].length);
    uint counter = 0; 
    for (uint i= 1;  i<= invesorsOnLoan[_loanId].length; i++) {
      _investorsOnThisLoan[counter]= invesorsOnLoan[_loanId][counter].investorId; 
      counter++;  

    }
    return _investorsOnThisLoan; 
  }

  function getInvestorsLoan(uint _investorId) public view returns (uint[] memory) {
    //Pass in investorAddress and see all the different loanIds they have funded 
    address _investorAddress = investorToOwner[_investorId]; 
    uint[] memory _loansOnThisInvestor = new uint[](loansOnInvestor[_investorAddress].length);
    uint counter = 0; 
    for (uint i= 1;  i<= loansOnInvestor[_investorAddress].length; i++) {
      _loansOnThisInvestor[counter]= loansOnInvestor[_investorAddress][counter].loanID; 
      counter++; 

    }
    return _loansOnThisInvestor; 
  }

  function calcul(uint a, uint b, uint precision) public pure returns ( uint) {
     return a*(10**precision)/b;
    }

  function _paybackInvestor(uint _investorId, uint _loanId, uint paybackAmount) public  {
    //address _investorAddress = investorToOwner[_investorId]; 
    //require(isBorrower(msg.sender)); //check if loan exists 
    require(isLoan(_loanId));



    uint borrower_balance = borrower[msg.sender].accountBalance;
    //uint _loanAmount = getInvestorFundingAmount(_loanId, _investorAddress); 
    //uint _loanAmount = getInvestorFundingAmount(_loanId, _investorId); 
    //uint paybackAmount = _loanAmount + _loanAmount/100*loan[_loanId].interestRate; //*100/100.//calcul(loan[_loanId].interestRate,100,5)//(_loanAmount*(loan[_loanId].interestRate/100.0));
    require(borrower_balance >= paybackAmount);  
    
    //investor[_investorAddress].accountBalance += paybackAmount; 
    investors[_investorId].accountBalance += paybackAmount;
    //investors[investor[msg.sender].investorId].accountBalance += paybackAmount; 
    //Increment Borrower account balance by the funding in both global arrays 
    //borrower[loanToBorrowerAddress[_loanId]].accountBalance -= paybackAmount;
    borrowers[loanToBorrower[_loanId].borrowerId].accountBalance -= paybackAmount; 

    changeFundingAmounts(_loanId,_investorId, paybackAmount); //change how much the investor is owed based on the paybackAmount from the borrower
    }
    //Make sure that the borrower exists
    //Make sure that the borrower loan exists
    //Get how much the investor invested into the loan
    //Calculate the additional interest to payback 
    // 

  //Functions to tell us if an address is an investor/borrower
  //Must have a borrower profile to create a loan 
  //Must have a lender profile to invest in a loan
  function isInvestor(address account) public view returns (bool) {return investor[account].EXISTS;}
  function isBorrower(address account) public view returns (bool) {return borrower[account].EXISTS;}
  function isLoan(uint _id) public view returns (bool) {return loan[_id].EXISTS;}




  //Toy example of adding to an array and printing it 
  /*string greeting = "What's up dog";
  uint[] s; 
  uint s2 = s.push(1);
  uint s3 = s.push(2);
  uint s4 = s.push(3); 
  function sayHello() public view returns (uint[]) {
    return s;
    }

  function addToS(uint num) public { 
    s.push(num); 
  }
  //End of Toy Example
  */
}


