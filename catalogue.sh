#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
W="\e[0m"

Logs_Folder="/var/log/Shell-Roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
#Here $0 gives the script name
MongoDB_Host="mongodb.chandana7.shop"
Log_File="$Logs_Folder/$Script_Name.log"
Script_Dir=$PWD

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
#####NodeJS#####
dnf module disable nodejs -y &>>$Log_File
VALIDATE $? "Disabling NodeJS"
dnf module enable nodejs:20 -y &>>$Log_File
VALIDATE $? "Enabling NodeJS"
dnf install nodejs -y &>>$Log_File
VALIDATE $? "Installing NodeJS"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    VALIDATE $? "Creating System User"
else
    echo -e "User already exists... $Y SKIPPING $W"
fi

mkdir -p /app 
VALIDATE $? "Creating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$Log_File
VALIDATE $? "Downloading catalogue application"
cd /app 
VALIDATE $? "Changing to app directory"
unzip /tmp/catalogue.zip &>>$Log_File
VALIDATE $? "unzip catalogue"

npm install &>>$Log_File
VALIDATE $? "Install Dependencies"

cp $Script_Dir/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue

cp $Script_Dir/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy Mongo repo"

dnf install mongodb-mongosh -y &>>$Log_File
VALIDATE $? "Install MongoDB client"

mongosh --host $MongoDB_Host </app/db/master-data.js &>>$Log_File
VALIDATE $? "Load catalogue products"

systemctl restart catalogue
VALIDATE $? "Restart catalogue"
