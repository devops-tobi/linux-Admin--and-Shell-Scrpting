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


#!/bin/bash

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
    echo "Checking if IAM group $GROUP_NAME exists..."
    if aws iam get-group --group-name "$GROUP_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "Group $GROUP_NAME already exists."
    else
        echo "Creating IAM group: $GROUP_NAME"
        if aws iam create-group --group-name "$GROUP_NAME" --region "$AWS_REGION"; then
            echo "Group $GROUP_NAME created successfully."
        else
            echo "Error: Failed to create group $GROUP_NAME." >&2
            exit 1
        fi
        
        echo "Attaching policy $POLICY_ARN to group $GROUP_NAME"
        if aws iam attach-group-policy --group-name "$GROUP_NAME" --policy-arn "$POLICY_ARN" --region "$AWS_REGION"; then
            echo "Policy attached successfully."
        else
            echo "Error: Failed to attach policy to group $GROUP_NAME." >&2
            exit 1
        fi
    fi
}

# Create the IAM group
create_iam_group

# Loop through each username to create IAM users
for username in "${USERNAMES[@]}"; do
    echo "Creating IAM user: $username"
    
    # Check if the user already exists
    if aws iam get-user --user-name "$username" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "User $username already exists. Skipping user creation."
        continue
    fi
    
    # Create IAM user
    if aws iam create-user --user-name "$username" --region "$AWS_REGION"; then
        echo "User $username created successfully."
    else
        echo "Error: Failed to create user $username." >&2
        continue  # Skip to the next user
    fi
    
    # Generate a random password
    password=$(generate_password)
    
    # Create login profile for the user
    if aws iam create-login-profile --user-name "$username" --password "$password" --password-reset-required --region "$AWS_REGION"; then
        echo "Login profile created for user $username."
    else
        echo "Error: Failed to create login profile for user $username." >&2
        continue  # Skip to the next user
    fi
    
    # Add user to the Admin group
    if aws iam add-user-to-group --user-name "$username" --group-name "$GROUP_NAME" --region "$AWS_REGION"; then
        echo "User $username added to group $GROUP_NAME."
    else
        echo "Error: Failed to add user $username to group $GROUP_NAME." >&2
        continue  # Skip to the next user
    fi
    
    echo "User $username created and added to group $GROUP_NAME with password: $password"
done

echo "All users processed."

