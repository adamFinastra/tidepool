import json
from web3 import Web3, HTTPProvider
import pandas as pd

class contractConnector: 
    
    def __init__(self,blockchain_address,compiled_contract_path, deployed_contract_address,defaultAccount=0): 
        self.blockchain_address = blockchain_address 
        self.compiled_contract_path = compiled_contract_path
        self.deployed_contract_address = deployed_contract_address 
        self.web3 = Web3(HTTPProvider(self.blockchain_address))
        self.web3.eth.defaultAccount = self.web3.eth.accounts[defaultAccount]
        with open(self.compiled_contract_path) as file:
            self.contract_json = json.load(file)  # load contract info as JSON
            self.contract_abi = self.contract_json['abi']
        self.contract = self.web3.eth.contract(address=self.deployed_contract_address, abi=self.contract_abi)
        
    def test_connection(self):
        return web3.isConnected()
    
    def get_borrrower_struct_info(self,borrower_id,address=False): 
        '''
        Get the borrower struct information from a specific borrower id
        '''
        if address: 
            borrower_id = self.contract.functions.BorrowerAddress2Id(address).call()
        borrower_struct = pd.DataFrame(self.contract.functions.borrowers(borrower_id).call()).T
        borrower_struct.columns = ["borrowerPublicKey","firstName","lastName","accountBalance","numLoans","borrowerId","Exists"]
        return borrower_struct
    
    def get_investor_struct_info(self,investor_id,address=False):
        '''
        Get the investor struct information from a specific investor_id id
        '''
        if address: 
            investor_id = self.contract.functions.InvestorAddress2Id(address).call()
        investor_struct = pd.DataFrame(self.contract.functions.investors(investor_id).call()).T
        investor_struct.columns = ["investorPublicKey","firstName","lastName","accountBalance","numInvestments","investorId","Exists"]
        return investor_struct
    
    def get_loan_struct_info(self,loan_id,appendBorrower=False):
        '''
        A function that will take in a loan id and return the loan struct information and optional the borrower who created it's information
        '''
        loan_struct = pd.DataFrame(self.contract.functions.loans(loan_id).call()).T
        loan_struct.columns = ["shortDescription","loanDescription", "tag","startDate","loanId","loanDuration","totalAmount","amountFunded","interestRate","numFunders","EXISTS","fundedStatus"]
        if appendBorrower: 
            borrower_address = self.contract.functions.loanToOwner(loan_id).call()
            #borrower_id = self.contract.functions.BorrowerAddress2Id(borrower_address).call()
            borrower_struct = self.get_borrrower_struct_info(borrower_id=None,address=borrower_address)
            loan_struct = pd.concat([loan_struct,borrower_struct],axis=1)
        return loan_struct
    
    def get_loan_contract_struct(self,lcid): 
        lc_struct = pd.DataFrame(self.contract.functions.loancontracts(lcid).call()).T
        lc_struct.columns = ["borrowerPublicKey","investorPublicKey","originalInvestmentAmount","originalInvestmentAmountInvestor","currentPaybackAmount",
                            "interestRate","loanTerm","loanId","loanContractId", "loanStartDate","shortDescription","loanDescription"]
        return lc_struct
    
    def getInvestorLoanContracts(self,investorAddress): 
        loancontractids = self.contract.functions.getLoanContractsInvestorHas(investorAddress).call()
        lcs = []
        for lcid in loancontractids: 
            lcs.append(self.get_loan_contract_struct(lcid))
        df_lcs = pd.concat(lcs,axis=0)
        return df_lcs
    
    def get_all_loans_struct_by_borrower(self,borrowerAddress):
        loan_ids = self.contract.functions.getLoansBorrowerHasCrerated(borrowerAddress).call()
        ls = []
        for lid in loan_ids: 
            ls.append(self.get_loan_struct_info(lid,True))
        df_loans = pd.concat(ls,axis=0)
        return df_loans
    
    
    def get_all_loan_struct_info(self,appendBorrower=False): 
        '''
        A function to get all of the loans that have been created that we 
        '''
        
        all_loan_ids = list(range(0,self.contract.functions.getTotalNumLoans().call()))
        ls = []
        for lid in all_loan_ids: 
            ls.append(self.get_loan_struct_info(lid,appendBorrower))
        df_loans = pd.concat(ls,axis=0)
        return df_loans
    
    def get_all_borrowers_struct_info(self):
        '''
        A function to get all struct info for all borrowers that we have 
        Looks at a range of the total number of borrowers for the id --> i.e. numTotalBorrowers = 7 means [0,1,2,...,6] for the ids as they are sequentially added
        Then we make a call to the function get_borrower_struct_info in our class in our loop of borrower ids
        Finally, convert it to a pandas dataframe 
        '''
        all_borrower_ids = list(range(0,self.contract.functions.getTotalNumBorrowers().call()))
        ls = []
        for bid in all_borrower_ids: 
            ls.append(self.get_borrrower_struct_info(bid))
        df_borrowers = pd.concat(ls,axis=0)
        return df_borrowers
    
    def get_all_investors_struct_info(self):
        '''
        A function to get all struct info for all borrowers that we have 
        Looks at a range of the total number of borrowers for the id --> i.e. numTotalBorrowers = 7 means [0,1,2,...,6] for the ids as they are sequentially added
        Then we make a call to the function get_borrower_struct_info in our class in our loop of borrower ids
        Finally, convert it to a pandas dataframe 
        '''
        all_investor_ids = list(range(0,self.contract.functions.getTotalNumInvestors().call()))
        ls = []
        for lid in all_investor_ids: 
            ls.append(self.get_investor_struct_info(lid))
        df_investors = pd.concat(ls,axis=0)
        return df_investors
    
    def get_investor_info_by_loanid(self,_loanId):
        all_investor_ids = self.contract.functions.getInvestorsByLoanId(_loanId).call()
        investor_amounts = self.contract.functions.getFundingAmountsByLoanId(_loanId).call()
        borrower_ids = self.contract.functions.getBorrowersOnLoan(_loanId).call()
        ls = []
        for iid in all_investor_ids: 
            print(iid)
            ls.append(self.get_investor_struct_info(None,address=iid))
        df_investors = pd.concat(ls,axis=0)
        df_investors["amountInvested"] = investor_amounts
        df_investors["loanId"] = _loanId
        df_investors["borrowerPublicKey"] = borrower_ids
        return df_investors
    
    
    def get_all_funded_loans(self):
        df_loans = self.get_all_loan_struct_info(True)
        df_funded_loans = df_loans[df_loans.numFunders > 0]
        return df_funded_loans
    
    
    def get_loan_info_by_investor(self,_investorAddress): 
        loanIds = self.contract.functions.getLoanIdsByInvestor(_investorAddress).call()
        ls = []
        ls2 = []
        for lid in loanIds: 
            ls.append(self.get_loan_struct_info(lid))
            ls2.append(self.get_investor_info_by_loanid(lid))
        df_ls = pd.concat(ls,axis=0)
        df_ls2 = pd.concat(ls2,axis=0)
        df_ls2 = df_ls2[df_ls2.loanId.isin(loanIds)]
        df_ls2 = df_ls2[df_ls2.investorPublicKey == _investorAddress]
        df_all = pd.concat([df_ls,df_ls2],axis=1)
        return df_all
    
    
    def get_investors_from_borrower(self,borrowerAddress):
        #Take in a borrower address and see all the people/amounts they have to pay back
        loans_created = self.contract.functions.getLoansBorrowerHasCrerated(borrowerAddress).call()
        ls = []
        for i in loans_created:
            ls.append(self.get_investor_info_by_loanid(i))
        df = pd.concat(ls,axis=0)
        df = df[df.borrowerPublicKey == borrowerAddress]
        return df
    
    
    def get_investor_payback_by_borrower_address(self,borrowerAddress):
        loans_borrower_created = self.contract.functions.getLoansBorrowerHasCrerated(borrowerAddress).call()
        contractids = []
        for i in loans_borrower_created: 
            cids = self.contract.functions.getLoanContractIdsFromLoanId(i).call()
            contractids.append(cids)
        contractids = [item for sublist in contractids for item in sublist]
        dta = []
        for i in contractids: 
            dta.append(self.get_loan_contract_struct(i))

        df_lcs = pd.concat(dta,axis=0)
        return df_lcs