from flask import Flask, request, redirect, url_for, flash, jsonify
import pandas as pd
import numpy as np

import json
from web3 import Web3, HTTPProvider
import pandas as pd
from ganacheconnector import contractConnector

from transformers import AutoModelForSequenceClassification, AutoTokenizer
from transformers import pipeline

from model_classifier import get_top_tag

from datetime import date, datetime

from dateutil.relativedelta import relativedelta


# 
#Sample Requests
'''
#-m equip stuff labor alpha moment rally program sting suggest bulk mesh abuse
* Get borrower details by their address: http://localhost:5000/get_borrower_info_by_address?address=0x04C2CcCf58ff9C74C40d5B90C241D3c56dB259e9
* Get investor details by their address: http://localhost:5000/get_investor_info_by_address?address=0x04C2CcCf58ff9C74C40d5B90C241D3c56dB259e9
* Get all information about our investors: http://localhost:5000/get_all_investors_info
* Get all information about our borrowers: http://localhost:5000/get_all_borrowers_info
* Get all loans that have been created on the marketplace: http://localhost:5000/get_marketplace_loans
* Get all investor payback information given a borrower address: http://localhost:5000/get_borrower_paybacks?address=0x9eBbb86593b4B6212FEA6c7905EAA85b352cf9Ea
* Get all loan contracts given an investor address: http://localhost:5000/get_investor_loan_contracts?&address=0x04C2CcCf58ff9C74C40d5B90C241D3c56dB259e9
* A borrower creating a loan: http://localhost:5000/create_loan?loan_description=need%20lunch%20for%20the%20week&loan_duration=4&loan_amount=5000&interest_rate=33&borrower_address=0x04C2CcCf58ff9C74C40d5B90C241D3c56dB259e9
* An investor funding a loan: http://localhost:5000/fund_loan?loan_id=1&funding_amount=222&investor_address=0x04C2CcCf58ff9C74C40d5B90C241D3c56dB259e9
* A borrower paying back an investor: http://localhost:5000/payback_investor?loan_id=4&investor_address=0x04C2CcCf58ff9C74C40d5B90C241D3c56dB259e9&payback_amount=250&borrower_address=0xEe3a3B19181D4E45e6aA6519339737c7aA0D89a3

'''


app = Flask(__name__)
app.config['JSON_SORT_KEYS'] = False

blockchain_address = 'http://127.0.0.1:8545'
compiled_contract_path = '../build/contracts/P2PTest.json'
deployed_contract_address = '0x6d72dC5be82840419bde6758D04Cc37102eB0473'
defaultAccount = 0

web3 = Web3(HTTPProvider(blockchain_address))
web3.eth.accounts[defaultAccount]
web3.eth.defaultAccount = web3.eth.accounts[defaultAccount]
c = contractConnector(blockchain_address,compiled_contract_path,deployed_contract_address,defaultAccount)

#LOAD MODEL
global classifier
classifier = pipeline("zero-shot-classification",model="valhalla/distilbart-mnli-12-3")
print("Model Loaded")


@app.route("/get_tag")
def gettoptag():
	loan_description = request.args.get('loan_description', default="*", type=str)
	top_tag = get_top_tag(classifier,loan_description)
	return jsonify({"top_tag":top_tag})


@app.route('/get_single_loan_struct_info', methods=['GET','POST'])
def getloanstructinfo():
	loan_id = request.args.get('loan_id', default="*", type=int)
	df = c.get_loan_struct_info(loan_id,True)
	return jsonify(df.to_dict('records'))

@app.route('/get_all_investors_info', methods=['GET','POST'])
def getallinvestorinfo():
	'''
	Return a dataframe that has all investor information 
	'''
	df = c.get_all_investors_struct_info()
	return jsonify(df.to_dict('records'))

@app.route('/get_all_borrowers_info', methods=['GET','POST'])
def getallborrowerinfo():
	'''
	Return a dataframe that has all borrower information
	'''
	df = c.get_all_borrowers_struct_info()
	return jsonify(df.to_dict('records'))

@app.route('/get_borrower_info_by_address',methods=['GET','POST'])
def getborrowerinfobyaddress(): 
	'''
	Return a dataframe that has all borrower information given a borrower address
	'''
	address = request.args.get('address', default = "*", type = str)
	df = c.get_borrrower_struct_info(None,address=address)
	return jsonify(df.to_dict('records'))

@app.route('/get_investor_info_by_address',methods=['GET','POST'])
def getinvestorinfobyaddress():
	address = request.args.get('address', default = "*", type = str)
	df = c.get_investor_struct_info(None,address=address)
	return jsonify(df.to_dict('records'))


@app.route('/get_marketplace_loans', methods=['GET','POST'])
def marketplaceloans():
	'''
	Get all loans that have been created in the marketplace
	'''
	df = c.get_all_loan_struct_info(True)
	return jsonify(df.to_dict('records'))

@app.route('/get_borrower_paybacks',methods=['GET','POST'])
def borrowerpaybacks(): 
	address = request.args.get('address', default = "*", type = str)
	df = c.get_investor_payback_by_borrower_address(address)
	get_names=True
	if get_names: 
	    investor_address = df.investorPublicKey.unique().tolist()
	    l = []
	    for i in investor_address: 
	        investor_data = c.get_investor_struct_info(None,address=i)
	        name_data = [i,investor_data.firstName[0], investor_data.lastName[0]]
	        l.append(name_data)
	    df_names = pd.DataFrame(l,columns=["investorPublicKey","investorFirstName","investorLastName"])
	    df = pd.merge(df, df_names, on="investorPublicKey")


	df_total_loan_amount_intererst = df.groupby("loanId").originalInvestmentAmountInvestor.sum()
	df_total_loan_amount_intererst = pd.DataFrame(df_total_loan_amount_intererst).reset_index()
	df_total_loan_amount_intererst = df_total_loan_amount_intererst.rename(columns={"originalInvestmentAmountInvestor":"totalLoanValueWithInterest"})
	df_total_loan_amount_intererst


	df_total_loan_amount_no_intererst = df.groupby("loanId").originalInvestmentAmount.sum()
	df_total_loan_amount_no_intererst = pd.DataFrame(df_total_loan_amount_no_intererst).reset_index()
	df_total_loan_amount_no_intererst = df_total_loan_amount_no_intererst.rename(columns={"originalInvestmentAmount":"totalLoanValueNoInterest"})


	def isPaidOff(x): 
	    if x == 0:
	        return 1
	    else:
	        return 0

	def correct_negs(x): 
	    if x <= 0 :
	        return 0
	    else: 
	        return x

	df["totalPaidBackSoFar"] = df["originalInvestmentAmount"] - df["currentPaybackAmount"]
	df["totalPaidBackSoFar"] = df.totalPaidBackSoFar.apply(lambda i: correct_negs(i))
	df["isPaidOff"] = df.currentPaybackAmount.apply(lambda i: isPaidOff(i))
	df["totalPaidBackSoFar"][df.isPaidOff == 1] = df.originalInvestmentAmountInvestor

	df_total_paidbacksofar = df.groupby("loanId").totalPaidBackSoFar.sum()
	df_total_paidbacksofar = pd.DataFrame(df_total_paidbacksofar).reset_index()
	df_total_paidbacksofar = df_total_paidbacksofar.rename(columns={"totalPaidBackSoFar":"totalPaidtoInvestors"})

	df = pd.merge(df,df_total_loan_amount_intererst,on='loanId')
	df = pd.merge(df,df_total_loan_amount_no_intererst,on='loanId')
	df = pd.merge(df,df_total_paidbacksofar,on='loanId')

	df_paidback = df[df.isPaidOff == 1]
	df_notpaidback = df[df.isPaidOff == 0]
	df_info = df[['loanId','interestRate','loanTerm','totalPaidBackSoFar','totalLoanValueWithInterest',"totalLoanValueNoInterest","totalPaidtoInvestors","borrowerPublicKey","shortDescription","loanDescription"]]
	df_info = df_info.groupby("loanId")[["loanTerm","totalLoanValueWithInterest","totalLoanValueNoInterest","totalPaidtoInvestors","interestRate","shortDescription","loanDescription"]].first().reset_index()
	js = []
	for idx,i in enumerate(df.loanId.unique()):
	    print(i)
	    s = {'loan_id':i}
	    try:
	        s["PaidBackDetails"] = df_paidback[df_paidback.loanId == i].to_dict('r')
	    except:
	        s["PaidBackDetails"] = []
	    try:
	        s["NotPaidBackDetails"] = df_notpaidback[df_notpaidback.loanId == i].to_dict('r')
	    except:
	        s["NotPaidBackDetails"] = []
	    try:
	        s["Info"] = df_info[df_info.loanId == i].to_dict('r')
	    except:
	        s["Info"] = []
	    js.append(s)
	#return jsonify(df.to_dict('records'))
	return jsonify(js)

@app.route('/get_investor_loan_contracts',methods=['GET','POST'])
def investorcontracts():
	address = request.args.get('address', default = "*", type = str)
	df = c.getInvestorLoanContracts(address)
	return jsonify(df.to_dict('records'))

@app.route('/create_loan', methods = ['GET','POST'])
def createloan():
	short_description = request.args.get('short_description', default="*", type=str)
	loan_description = request.args.get('loan_description', default = "*", type = str)
	tag = get_top_tag(classifier,loan_description)
	start_date = request.args.get("start_date", default="*", type=str)
	#tag = request.args.get("tag",default="*",type=str)
	loan_duration = request.args.get('loan_duration', default = "*", type = int)
	#end_date = datetime.strptime(start_date, "%Y-%m-%d") + relativedelta(months=+loan_duration)
	#end_date = end_date.strftime('%Y-%m-%d')
	loan_amount = request.args.get('loan_amount', default = "*", type = int)
	interest_rate = request.args.get('interest_rate',default="*",type = int)
	borrower_address = request.args.get('borrower_address', default = "*", type = str)
	#message = c.contract.functions.createLoan(short_description,loan_description, tag, start_date, end_date, loan_duration, loan_amount, interest_rate).transact({'from': borrower_address})
	message = c.contract.functions.createLoan(short_description,loan_description, tag, start_date, loan_duration, loan_amount, interest_rate).transact({'from': borrower_address})
	message_receipt = web3.eth.wait_for_transaction_receipt(message)
	return {'status':'loan created'}


@app.route('/fund_loan', methods=['GET','POST'])
def fundloan():
	loan_id = request.args.get('loan_id', default="*", type=int)
	funding_amount = request.args.get('funding_amount', default="*", type=int)
	investor_address = request.args.get('investor_address', default="*", type=str)
	message = c.contract.functions.fundLoan(loan_id,funding_amount).transact({'from':investor_address})
	message_receipt = web3.eth.wait_for_transaction_receipt(message)
	return {'status':'loan funded'}

@app.route('/payback_investor', methods=['GET','POST'])
def paybackinvestor():
	#need to get the id from the investor publickey 
	loan_id = request.args.get('loan_id', default="*", type=int)
	print(loan_id)
	investor_address = request.args.get('investor_address', default="*", type=str)
	investor_id = c.contract.functions.InvestorAddress2Id(investor_address).call()
	print(investor_id)
	payback_amount = request.args.get('payback_amount', default="*", type=int)
	print(payback_amount)
	borrower_address = request.args.get('borrower_address', default="*", type=str)
	message = c.contract.functions._paybackInvestor(investor_id,loan_id,payback_amount).transact({'from':borrower_address})
	message_receipt = web3.eth.wait_for_transaction_receipt(message)
	return {'status': 'payback created'}




if __name__ == '__main__':
	
	app.run(debug=True, host='0.0.0.0')