#!/bin/bash

# Checking the number of arguments
if [ "$#" -ne 0 ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

# Accessing the first argument
ENVIRONMENT=$1

# Acting based on the argument value
if [ "$ENVIRONMENT" == "local" ]; then
  echo "Running script for Local Environment..."
elif [ "$ENVIRONMENT" == "testing" ]; then
  echo "Running script for Testing Environment..."
elif [ "$ENVIRONMENT" == "production" ]; then
  echo "Running script for Production Environment..."
else
  echo "Invalid environment specified. Please use 'local', 'testing', or 'production'."
  exit 2
fi


# Variables
USERNAMES=("employee1" "employee2" "employee3" "employee4" "employee5")  # List of new employees
GROUP_NAME="Admin"  # Name of the IAM group
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"  # AWS-managed policy for administrative privileges
AWS_REGION="us-east-1"  # Specify your AWS region

# Function to generate a random password
generate_password() {
    < /dev/urandom tr -dc 'A-Za-z0-9_@#%&*' | head -c 12
}

# Function to create an IAM group
create_iam_group() {
    echo "Creating IAM group: $GROUP_NAME"
    aws iam create-group --group-name "$GROUP_NAME" --region "$AWS_REGION"
    
    echo "Attaching policy $POLICY_ARN to group $GROUP_NAME"
    aws iam attach-group-policy --group-name "$GROUP_NAME" --policy-arn "$POLICY_ARN" --region "$AWS_REGION"
}

# Create the IAM group
create_iam_group

# Loop through each username to create IAM users
for username in "${USERNAMES[@]}"; do
    echo "Creating IAM user: $username"
    
    # Create IAM user
    aws iam create-user --user-name "$username" --region "$AWS_REGION"
    
    # Generate a random password
    password=$(generate_password)
    
    # Create login profile for the user
    aws iam create-login-profile --user-name "$username" --password "$password" --password-reset-required --region "$AWS_REGION"
    
    # Add user to the Admin group
    aws iam add-user-to-group --user-name "$username" --group-name "$GROUP_NAME" --region "$AWS_REGION"
    
    echo "User $username created and added to group $GROUP_NAME with password: $password"
done

echo "All users created and added to the Admin group successfully."
