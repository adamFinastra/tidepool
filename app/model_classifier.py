from transformers import AutoModelForSequenceClassification, AutoTokenizer
from transformers import pipeline
import pandas as pd
import numpy as np

def get_top_tag(_classifier,loanDescription):
	categories = ['grocery', 'medical bills', 'home improvement', 'debt', 'job Loss', 'auto repair', 'pet care', 'funeral', 'business needs']
	result = _classifier(loanDescription,categories,multi_label=False)
	top_tag = result["labels"][0]
	return top_tag