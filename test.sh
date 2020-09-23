sudo docker build . -t aws-ecr-proxy && sudo docker run -p 80:80 -e AWS_ROLE_ARN=arn:aws:iam::147860731529:role/cdp-test-role aws-ecr-proxy:latest
