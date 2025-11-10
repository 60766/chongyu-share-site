#!/usr/bin/env python3
import paramiko

HOST = "47.94.254.130"
USERNAME = "root"

passwords = ["3Qq123456.", "3Qq123456"]

for pwd in passwords:
    print(f"尝试密码: {pwd}")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(HOST, username=USERNAME, password=pwd, timeout=5)
        print(f"✅ 成功！正确密码是: {pwd}")
        ssh.close()
        break
    except paramiko.AuthenticationException:
        print(f"❌ 密码错误")
    except Exception as e:
        print(f"❌ 其他错误: {e}")
    finally:
        ssh.close()
