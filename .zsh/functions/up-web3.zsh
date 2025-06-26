function up-web3() {
  local allowed_dir="/Users/navy/gitlab/web3_property"
  local current_dir
  current_dir=$(pwd)

  if [ "$current_dir" != "$allowed_dir" ]; then
    echo "错误: 该命令只能在 $allowed_dir 目录下执行"
    return 1
  fi

  # 创建时间戳文件名
  local timestamp
  timestamp="$(date +%Y%m%d_%H%M%S)"
  local filename="web3_property_${timestamp}.tar.gz"
  local filepath="$PWD/downloads/${filename}"

  # 确保downloads目录存在
  mkdir -p "$PWD/downloads"

  # 创建tar包，排除不需要的目录，确保跨平台兼容性
  echo "正在创建压缩包 ${filename}..."
  tar --exclude="web3base/local_config" --exclude=".git" --exclude=".venv" --exclude="tool" --exclude="downloads" --exclude="**/__pycache__" --exclude="**/*.pyc" --exclude="nacos-data" --exclude="k8s" -czf "$filepath" .

  if [ $? -ne 0 ]; then
    echo "创建压缩包失败"
    return 1
  fi

  # 验证压缩包
  echo "验证压缩包完整性..."
  gzip -t "$filepath"
  if [ $? -ne 0 ]; then
    echo "压缩包验证失败，可能已损坏"
    return 1
  fi

  # FTP服务器信息
  local upload_url="ftp://ftp.appsflyer.club/xiejianhe/"
  local username="xbftp"
  local password="xiaobu2016"

  # 上传到FTP服务器
  echo "正在上传 ${filename} 到FTP服务器..."
  local filesize
  filesize=$(stat -f "%z" "$filepath")
  echo "本地文件大小: ${filesize} 字节"

  # 使用二进制模式和断点续传上传文件
  curl -T "$filepath" --ftp-create-dirs -k --connect-timeout 60 --retry 3 --retry-delay 5 -C - -u "${username}:${password}" "${upload_url}${filename}"

  if [ $? -eq 0 ]; then
    # 验证远程文件大小
    remote_size=$(curl -s -I -u "${username}:${password}" "${upload_url}${filename}" | grep -i "Content-Length" | awk '{print $2}' | tr -d '\r\n')
    echo "远程文件大小: ${remote_size:-未知} 字节"

    if [ -n "$remote_size" ] && [ "$remote_size" -eq "$filesize" ]; then
      echo "文件成功上传并验证到 ${upload_url}${filename}"
    else
      echo "警告: 文件大小不匹配，上传可能不完整"
      echo "本地: ${filesize} 字节，远程: ${remote_size:-未知} 字节"
      return 1
    fi
  else
    echo "文件上传失败"
    return 1
  fi

  echo "完成！本地文件保存在 ${filepath}"
  return 0
}
