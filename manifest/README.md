
# MetalLB install script 설치 가이드
* 해당 install scripte는 폐쇄망 기준 가이드입니다.

## Prerequisites
설치를 진행하기 전 아래의 과정을 통해 필요한 이미지 및 yaml 파일을 준비한다.
1. **폐쇄망에서 설치하는 경우** 사용하는 image repository에 metallb 설치 시 필요한 이미지를 push한다. 

    * 작업 디렉토리 생성 및 환경 설정
    ```bash
    $ mkdir -p ~/metallb-install
    $ export METALLB_HOME=~/metallb-install
    $ export METALLB_VERSION=v0.9.3
    $ export REGISTRY=172.22.8.106:5000
    $ cd $METALLB_HOME
    ```

    * 외부 네트워크 통신이 가능한 환경에서 필요한 이미지를 다운받는다.
    ```bash
    $ sudo docker pull metallb/controller:${METALLB_VERSION}
    $ sudo docker save metallb/controller:${METALLB_VERSION} > metallb-controller_${METALLB_VERSION}.tar
    $ sudo docker pull metallb/speaker:${METALLB_VERSION}
    $ sudo docker save metallb/speaker:${METALLB_VERSION} > metallb-speaker_${METALLB_VERSION}.tar
    ```

2. 위의 과정에서 생성한 tar 파일들을 폐쇄망 환경으로 이동시킨 뒤 사용하려는 registry에 이미지를 push한다.
    ```bash
    $ sudo docker load < metallb-controller_${METALLB_VERSION}.tar
    $ sudo docker load < metallb-speaker_${METALLB_VERSION}.tar

    $ sudo docker tag metallb/controller:${METALLB_VERSION} ${REGISTRY}/metallb/controller:${METALLB_VERSION}
    $ sudo docker tag metallb/speaker:${METALLB_VERSION} ${REGISTRY}/metallb/speaker:${METALLB_VERSION}

    $ sudo docker push ${REGISTRY}/metallb/controller:${METALLB_VERSION}
    $ sudo docker push ${REGISTRY}/metallb/speaker:${METALLB_VERSION}
    ```

## 설치 가이드
0. [metallb.config 설정](#step0 "step0")
1. [metallb 설치](#step1 "step1")
2. [metallb 대역 설정](#step2 "step2")

<h2 id="step0"> Step0. metallb.config 설정 </h2>

* 목적 : `metallb 설치를 위한 config 변수 설정`
* 생성 순서 : 
    * 환경에 맞는 config 내용을 작성합니다.
        * registry={IP:PORT}
            * 폐쇄망에서의 image registry 정보를 설정합니다.
            * ex) registry=172.22.8.106:5000
        * metallb_version={METALLB_VERSION}
            * ex) metallb_version=v0.9.3
        * metallb_namespace={METALLB_NAMESPACE}
            * ex) metallb_version=metallb-system

<h2 id="step1"> Step 1. metallb 설치 </h2>

* 목적 : `metallb 설치`
* 생성 순서
    * metallb-install 스크립트 실행
        ```bash
        $ cd ~/metallb-install/manifest
        $ ./install-metallb.sh install
        ```

<h2 id="step2"> Step 2. metallb 대역 설정 </h2>

* 목적 : `metallb에서 사용할 대역 설정 (호스트와 동일한 대역 사용)`
* 생성 순서: metallb_cidr.yaml 적용  `ex) kubectl apply -f yaml/metallb_cidr.yaml`
* 비고 :
    ```bash
    apiVersion: v1
    kind: ConfigMap
    metadata:
      namespace: metallb-system
      name: config
    data:
      config: |
        address-pools:
        - name: default
          protocol: layer2
          addresses:
          - 172.22.8.160-172.22.8.180
          - 172.22.8.184-172.22.8.190
    ```
    
## 삭제 가이드
1. 이전 설치시 metallb.yaml을 설치한 디렉토리로 이동 및 metallb, metallb_namespace 삭제
    * 작업 디렉토리 생성 및 환경 설정
    ```bash
    $ cd ~/metallb-install/manifest
    $ ./install-metallb.sh uninstall
    ```
