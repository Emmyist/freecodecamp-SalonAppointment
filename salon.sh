#!/bin/bash

# Database connection details
DB_USERNAME="freecodecamp"
DB_NAME="salon"
DB_CONNECT="psql --username=${DB_USERNAME} --dbname=${DB_NAME}"

# Function to display the salon header
function display_header() {
  echo -e "\n~~~~~ MY SALON ~~~~~\n"
  echo -e "\nWelcome to My Salon, how can I help you?\n"
}

# Function to display the list of services
function display_services() {
  local services_list=$(${DB_CONNECT} -t -c "SELECT service_id, name FROM services;")
  while IFS= read -r line; do
    echo "$line" | awk -F "|" '{ printf "%d)%s\n", $1, $2 }'
  done <<< "$services_list"
}

# Function to prompt for customer name
function prompt_customer_name() {
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
}

# Function to prompt for customer details
function prompt_customer_details() {
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Check if the phone number exists in the customers table
  if ! customer_exists; then
    prompt_customer_name
  else
    # Retrieve the customer's name from the database
    CUSTOMER_NAME=$(${DB_CONNECT} -t -c "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  fi

  echo -e "\nWhat time would you like your $service_name, $CUSTOMER_NAME?"
  read SERVICE_TIME
}

# Check if the service_id exists
function service_exists() {
  local exists=$(${DB_CONNECT} -t -c "SELECT 1 FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  [[ -n "$exists" ]]
}

# Check if the phone number exists in the customers table
function customer_exists() {
  local exists=$(${DB_CONNECT} -t -c "SELECT 1 FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  [[ -n "$exists" ]]
}

# Insert customer details into the customers table
function insert_customer_details() {
  ${DB_CONNECT} -c "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE');"
}

# Insert appointment into the appointments table
function insert_appointment() {
  local customer_id
  if customer_exists; then
    customer_id=$(${DB_CONNECT} -t -c "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  else
    insert_customer_details
    customer_id=$(${DB_CONNECT} -t -c "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  fi

  ${DB_CONNECT} -c "INSERT INTO appointments (customer_id, service_id, time) VALUES ($customer_id, $SERVICE_ID_SELECTED, '$SERVICE_TIME');"
}

# Display appointment confirmation message
function display_confirmation() {
  echo ""
  echo "I have put you down for a $service_name at $SERVICE_TIME, $CUSTOMER_NAME."
}

# Main script
display_header
display_services

# Prompt for service_id
while true; do
  # read -p "" SERVICE_ID_SELECTED
  read SERVICE_ID_SELECTED

  if service_exists; then
    break
  else
    echo -e "\nI could not find that service. What would you like today?"
    display_services
  fi
done

# Fetch service_name based on service_id
service_name=$(${DB_CONNECT} -t -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")

# Prompt for customer details
prompt_customer_details

# Insert appointment into the appointments table
insert_appointment

# Display appointment confirmation
display_confirmation
