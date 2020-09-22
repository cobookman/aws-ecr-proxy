#!/bin/sh

nx_conf=/etc/nginx/nginx.conf

AWS_IAM='http://169.254.169.254/latest/dynamic/instance-identity/document'
AWS_FOLDER='/root/.aws'

config_write() {
    REGION=$(wget -q -O- ${AWS_IAM} | grep 'region' | cut -d'"' -f4)
    echo "" >> /root/.aws/config
    echo "[profile default]" >> /root/.aws/config
    echo "region = $REGION"
    echo "role_arn = $ASSUME_ROLE" >> /root/.aws/config
    echo "credential_source = Ec2InstanceMetadata" >> /root/.aws/config
    chmod 600 -R ${AWS_FOLDER}
}

test_iam() {
    wget -q -O- ${AWS_IAM} | grep -q 'region'
}

test_config() {
    grep -qrni $@ ${AWS_FOLDER}
}


# Write aws cli config
config_write


# Check for ecr auth token generation acls
if aws ecr get-authorization-token | grep expiresAt
then
    echo "iam role configured to allow ecr access"
else
    echo "unable to get auth token"
    exit 1
fi

#a update the auth token
if [ "$REGISTRY_ID" = "" ]
then 
    aws_cli_exec=$(aws ecr get-login --no-include-email)
else
    aws_cli_exec=$(aws ecr get-login --no-include-email --registry-ids $REGISTRY_ID)
fi

auth=$(grep  X-Forwarded-User ${nx_conf} | awk '{print $4}'| uniq|tr -d "\n\r")
token=$(echo "${aws_cli_exec}" | awk '{print $6}')
auth_n=$(echo AWS:${token}  | base64 |tr -d "[:space:]")
reg_url=$(echo "${aws_cli_exec}" | awk '{print $7}')

sed -i "s|${auth%??}|${auth_n}|g" ${nx_conf}
sed -i "s|REGISTRY_URL|$reg_url|g" ${nx_conf}

/renew_token.sh &

exec "$@"
