Updated project: 
1 - rust and go are not insalled; decomment in the docker file to install them 
2 - start_challenge.sh dynamically looks for file bash to run the challenge e.g " eg: run_challenge" to 
    'e.g: run_challenge' comes with challenge built challenge to install dependecies/ not in base machine
3 - start.sh launches machine:  VNC , noVNC , start_challenges

```
#web3-hamonis


docker build -t hamonis:base .


docker run -d --name hamonis-base -p 5901:5901 -p 8080:8080 hamonis:base

```
