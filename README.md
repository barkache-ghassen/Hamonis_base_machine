```
#web3-hamnis


docker build -t hamonis:base .


docker run -d --name hamonis-base -p 5901:5901 -p 8080:8080 hamonis:base

```