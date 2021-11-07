# ``iOSEncrypt``

iOS Encrypt for iiDecide

## Overview

The iiDecide chat scheme has 5 parts

1. The client generates a public/private key for a chat room
    1a. The public/private key will be an RSA key
2. The client accepts the chat room and sends the *public* key to the server
3. The server generates a random key to be used for AES256 encryption (same key for all users)
    3a. The server will encrypt this key with *the public key of each client in that chatroom*.
    3b. The server will add the new AES256 key (encrypted using each clients' public key) to an array of keys
4. The client can query for his/her encrypted AES256 encryption key, which the sever will give in encrypted form.
5. The client can decrypt that AES256 key with his/her private key and use the AES256 encryption key to encrypt/decrypt messages

As an example, when a chat room is created with users `A` and `B`, both `A` and `B` will send over their public keys `pub_A` and `pub_B`. The server will create an AES256 encryption key `aes_key1` and store it in Firebase as
```
data = {
    "keys": [
        {
            "A": RSA(aes_key1, pub_A),
            "B": RSA(aes_key1, pub_B)
        }
    ]
}
```
Now, user `A` or `B` can fetch their encrypted key by accessing `data["keys"][-1]["A"]` or `data["keys"][-1]["B"]`, and decrypt said key using their private keys to get `aes_key1`. They can then use this key to communicate between each other.

If a new user `C` comes along, they will send their public key to the server and the server will generate *a new AES encryption key*, `aes_key2`. It will *append* that new key encrypted by each client's public key to the array of keys:
```
data = {
    "keys": [
        {
            "A": RSA(aes_key1, pub_A),
            "B": RSA(aes_key1, pub_B)
        },
        {
            "A": RSA(aes_key2, pub_A),
            "B": RSA(aes_key2, pub_B),
            "C": RSA(aes_key2, pub_C)
        },
    ]
}
```
This means users `A`, `B`, and `C` must always use the *last* (or most recent) key when sending messages so that all users can see the message.
