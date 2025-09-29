#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
W="\e[0m"
Logs_Folder="/var/log/Shell-Roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
#Here $0 gives the script name
Log_File="$Logs_Folder/$Script_Name.log"

User_id=$(id -u)

mkdir -p $Logs_Folder
echo "Script started executed at:$(date)"  | tee -a $Log_File                               

if [ $User_id -ne 0 ]; then
    echo "Error:Please run this Script with root privilege"
    exit 1 #failure is other than 0
fi

VALIDATE(){ #Functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 is...$R FAILURE $W " | tee -a $Log_File 
        exit 1
    else 
        echo -e "$2 is...$G SUCCESS $W" | tee -a $Log_File 
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-org -y &>>$Log_File
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$Log_File
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$Log_File
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "Restarted MongoDB"

