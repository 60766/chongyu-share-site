#!/usr/bin/env python3
import paramiko
import time
import sys

HOST = "47.94.254.130"
USERNAME = "root"
PASSWORD = "3Qq123456."
REMOTE_DIR = "/var/www/chongyu-backend"

def run_ssh_command(ssh, command, print_output=True):
    stdin, stdout, stderr = ssh.exec_command(command)
    output = stdout.read().decode('utf-8')
    error = stderr.read().decode('utf-8')
    if print_output and output:
        print(output)
    if error:
        print(error, file=sys.stderr)
    return output, error

def main():
    print("=== 连接服务器 ===")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(HOST, username=USERNAME, password=PASSWORD, timeout=10)
        print(f"✓ 已连接到 {HOST}\n")
        
        print("=== 步骤1: 检查当前配置 ===")
        run_ssh_command(ssh, f"cd {REMOTE_DIR} && cat production.env | grep CREDITS || echo '未找到CREDITS配置'")
        
        print("\n=== 步骤2: 上传server.js ===")
        sftp = ssh.open_sftp()
        sftp.put('server.js', f'{REMOTE_DIR}/server.js')
        sftp.close()
        print("✓ server.js 已上传")
        
        print("\n=== 步骤3: 备份并更新配置 ===")
        backup_cmd = f"cd {REMOTE_DIR} && cp production.env production.env.backup_$(date +%Y%m%d_%H%M%S)"
        run_ssh_command(ssh, backup_cmd, print_output=False)
        print("✓ 配置已备份")
        
        # 更新费率
        update_cmd = f"""cd {REMOTE_DIR} && \
if grep -q '^CREDITS_PER_1K_TOKENS=' production.env; then \
    sed -i 's/^CREDITS_PER_1K_TOKENS=.*/CREDITS_PER_1K_TOKENS=11/' production.env; \
else \
    echo 'CREDITS_PER_1K_TOKENS=11' >> production.env; \
fi"""
        run_ssh_command(ssh, update_cmd, print_output=False)
        
        # 删除旧配置
        run_ssh_command(ssh, f"cd {REMOTE_DIR} && sed -i '/^CREDITS_PER_DOUBAO_SEED_VISION=/d' production.env", print_output=False)
        run_ssh_command(ssh, f"cd {REMOTE_DIR} && sed -i '/^CREDITS_PER_DOUBAO_VISION_PRO=/d' production.env", print_output=False)
        print("✓ 配置已更新")
        
        print("\n=== 新配置内容 ===")
        run_ssh_command(ssh, f"cd {REMOTE_DIR} && cat production.env")
        
        print("\n=== 步骤4: 重启服务 ===")
        run_ssh_command(ssh, "pm2 restart chongyu-backend --update-env")
        time.sleep(3)
        
        print("\n=== 服务状态 ===")
        run_ssh_command(ssh, "pm2 list | grep chongyu-backend")
        
        print("\n=== 验证日志 ===")
        run_ssh_command(ssh, "pm2 logs chongyu-backend --lines 20 --nostream | tail -20")
        
        print("\n✅ 部署完成！")
        
    except Exception as e:
        print(f"❌ 错误: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        ssh.close()

if __name__ == "__main__":
    main()
