# Consul ESM - Failed Servcie monitoring



![img](https://raw.githubusercontent.com/Great-Stone/images/master/picgo/H6K7Nf8ZzeaFwpp5MeELmbCIsFu_9VkAmaDfVVTeN5G8RGt3kqBbn16gNEOqhZfiIlWAH-sdeX920VZZW6Oe2PVGPyToRglHjF7Emgy40pJGw8mEDSBJcG-hydNi_lDz7tubdZbsli_cfsErksmLIw%3Ds2048.png)



![img](https://raw.githubusercontent.com/Great-Stone/images/master/picgo/OZZhgAsiU7-ALRGV3KKUxQ4jbqsYA9zK1X61o1IFbqR_nqlN2N5ybEeubJS3MtdKfntUBfCjTMnr6j2jB8rPwFpiIOZsN2rzfbwfX5nIzb7ALzTRfQmJ6WbCaZLDttSUyAKV-heoOT7kFa_CJRfL3w%3Ds2048.png)



## Lambda Test

```sh
consul-template -consul-addr=http://43.201.72.246:8500 -template="consul_template/healthy-services-json.tpl:healthy-services.json" -once
```

```sh
curl https://idaq6o3euegkliak3bea72fq4q0juilh.lambda-url.ap-northeast-2.on.aws/ \
    -H 'Content-Type: application/json' \
    -d @healthy-services.json
```