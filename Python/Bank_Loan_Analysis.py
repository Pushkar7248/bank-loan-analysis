import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# Load Dataset
BASE_DIR = Path(__file__).resolve().parent.parent
df = pd.read_csv(BASE_DIR / "Data" / "Clean_Bank_Loan_Data.csv")
print("FIRST 5 RECORDS")
print(df.head())

print("\nDATASET INFORMATION")
df.info()

print("\nDATASET SHAPE")
print(df.shape)

print("\nCOLUMN NAMES")
print(df.columns)

print("\nSTATISTICAL SUMMARY")
print(df.describe())


#-- BASIC BANK LOAN STATISTICS

print("\n========== BASIC LOAN STATISTICS ==========")

# 1. Total Number of Loans
total_loans = df["Loan_ID"].count()
print("Total Loans:", total_loans)

# 2. Total Loan Amount
total_loan_amount = df["Loan_Amount"].sum()
print("Total Loan Amount:", total_loan_amount)

# 3. Average Loan Amount
average_loan = df["Loan_Amount"].mean()
print("Average Loan Amount:", round(average_loan, 2))

# 4. Highest Loan Amount
highest_loan = df["Loan_Amount"].max()
print("Highest Loan Amount:", highest_loan)

# 5. Lowest Loan Amount
lowest_loan = df["Loan_Amount"].min()
print("Lowest Loan Amount:", lowest_loan)

# 6. Average Customer Income
average_income = df["Annual_Income"].mean()
print("Average Annual Income:", round(average_income, 2))

# 7. Average Credit Score
average_credit = df["Credit_Score"].mean()
print("Average Credit Score:", round(average_credit, 2))

# 8. Average Interest Rate
average_interest = df["Interest_Rate"].mean()
print("Average Interest Rate:", round(average_interest, 2))

# 9. Highest Credit Score
highest_credit = df["Credit_Score"].max()
print("Highest Credit Score:", highest_credit)

# 10. Lowest Credit Score
lowest_credit = df["Credit_Score"].min()
print("Lowest Credit Score:", lowest_credit)


#-- LOAN STATUS ANALYSIS

# 1. Count loans by status
print("\nLOAN STATUS COUNT")
print(df["Loan_Status"].value_counts())

# 2. Calculate loan status percentages
print("\nLOAN STATUS PERCENTAGE")
status_percentage = df["Loan_Status"].value_counts(normalize=True) * 100
print(status_percentage.round(2))

# 3. Total loan amount by status
print("\nTOTAL LOAN AMOUNT BY STATUS")
status_amount = df.groupby("Loan_Status")["Loan_Amount"].sum()
print(status_amount)

# 4. Average loan amount by status
print("\nAVERAGE LOAN AMOUNT BY STATUS")
average_status_loan = df.groupby("Loan_Status")["Loan_Amount"].mean()
print(average_status_loan.round(2))

# 5. Charged Off loan analysis
charged_off = df[df["Loan_Status"] == "Charged Off"]

print("\nCHARGED OFF ANALYSIS")
print("Total Charged Off Loans:", len(charged_off))

print("Total Charged Off Amount:",
      charged_off["Loan_Amount"].sum())

print("Average Charged Off Loan:",
      round(charged_off["Loan_Amount"].mean(), 2))

# 6. Fully Paid loan analysis
fully_paid = df[df["Loan_Status"] == "Fully Paid"]

print("\nFULLY PAID ANALYSIS")
print("Total Fully Paid Loans:", len(fully_paid))

print("Total Fully Paid Amount:",
      fully_paid["Loan_Amount"].sum())

# 7. Credit score comparison by loan status
print("\nAVERAGE CREDIT SCORE BY STATUS")
credit_analysis = df.groupby("Loan_Status")["Credit_Score"].mean()
print(credit_analysis.round(2))


# PART 4 - DATA VISUALIZATION

import os

# Create Charts Folder
chart_folder = "Charts"
os.makedirs(chart_folder, exist_ok=True)

# CHART 1 - LOAN STATUS DISTRIBUTION

plt.figure(figsize=(9, 6))

status_counts = df["Loan_Status"].value_counts()

plt.pie(
    status_counts,
    labels=status_counts.index,
    autopct="%1.1f%%",
    startangle=90
)

plt.title("Bank Loan Status Distribution")
plt.tight_layout()

plt.savefig(os.path.join(chart_folder, "loan_status_distribution.png"))
plt.show()

# CHART 2 - LOAN AMOUNT BY STATUS

plt.figure(figsize=(10, 6))

status_amount = df.groupby("Loan_Status")["Loan_Amount"].sum()

sns.barplot(
    x=status_amount.index,
    y=status_amount.values
)

plt.title("Total Loan Amount by Status")
plt.xlabel("Loan Status")
plt.ylabel("Total Loan Amount")
plt.xticks(rotation=20)

plt.tight_layout()

plt.savefig(os.path.join(chart_folder, "loan_amount_by_status.png"))
plt.show()

# CHART 3 - CREDIT SCORE DISTRIBUTION

plt.figure(figsize=(10, 6))

sns.histplot(
    data=df,
    x="Credit_Score",
    bins=15,
    kde=True
)

plt.title("Customer Credit Score Distribution")
plt.xlabel("Credit Score")
plt.ylabel("Number of Customers")

plt.tight_layout()

plt.savefig(os.path.join(chart_folder, "credit_score_distribution.png"))
plt.show()

print("All charts saved successfully!")

