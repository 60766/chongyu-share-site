#!/usr/bin/env python3
"""
远程测试视觉API积分扣除
"""

import paramiko
import time
import sys

def run_remote_test():
    host = '172.24.42.243'
    username = 'root'
    password = '3Qq123456.'
    
    print("正在连接服务器...")
    
    # 创建SSH客户端
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        client.connect(host, username=username, password=password, timeout=10)
        print("✓ 连接成功\n")
        
        commands = [
            ("检查环境配置", "cd /var/www/chongyu-backend && grep 'CREDITS_PER_.*_VISION' production.env"),
            ("创建测试账户", "curl -s -X POST http://localhost:3000/api/wallet/init -H 'Content-Type: application/json' -d '{\"appAccountToken\":\"vision-test-004\"}'"),
            ("充值5000积分", "curl -s -X POST http://localhost:3000/api/wallet/balance -H 'Content-Type: application/json' -d '{\"appAccountToken\":\"vision-test-004\",\"amount\":5000}'"),
            ("调用视觉API (doubao-seed, 应扣10积分)", "curl -s -X POST http://localhost:3000/api/vision -H 'Content-Type: application/json' -H 'X-App-Account-Token: vision-test-004' -d '{\"model\":\"doubao-seed-1-6-vision-250815\",\"messages\":[{\"role\":\"user\",\"content\":\"你好\"}],\"max_tokens\":50}'"),
            ("查看剩余积分 (应该是4990)", "curl -s http://localhost:3000/api/wallet/balance?appAccountToken=vision-test-004"),
            ("调用视觉API (doubao-vision-pro, 应扣20积分)", "curl -s -X POST http://localhost:3000/api/vision -H 'Content-Type: application/json' -H 'X-App-Account-Token: vision-test-004' -d '{\"model\":\"doubao-vision-pro-32k\",\"messages\":[{\"role\":\"user\",\"content\":\"你好\"}],\"max_tokens\":20}'"),
            ("查看最终积分 (应该是4970)", "curl -s http://localhost:3000/api/wallet/balance?appAccountToken=vision-test-004"),
        ]
        
        print("="*60)
        print("视觉API积分扣除测试")
        print("="*60)
        print()
        
        for i, (description, cmd) in enumerate(commands, 1):
            print(f"{i}. {description}:")
            stdin, stdout, stderr = client.exec_command(cmd)
            output = stdout.read().decode('utf-8').strip()
            error = stderr.read().decode('utf-8').strip()
            
            if output:
                print(output)
            if error:
                print(f"错误: {error}", file=sys.stderr)
            print()
            
            # API调用后稍等一下
            if 'curl' in cmd and 'POST' in cmd:
                time.sleep(1)
        
        print("="*60)
        print("测试完成！")
        print("预期积分变化: 5000 -> 4990 -> 4970")
        print("="*60)
        
    except paramiko.ssh_exception.NoValidConnectionsError:
        print("✗ 无法连接到服务器，请检查网络")
        return False
    except paramiko.ssh_exception.AuthenticationException:
        print("✗ 认证失败，请检查密码")
        return False
    except Exception as e:
        print(f"✗ 错误: {e}")
        return False
    finally:
        client.close()
    
    return True

if __name__ == '__main__':
    success = run_remote_test()
    sys.exit(0 if success else 1)

