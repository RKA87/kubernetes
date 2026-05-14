if [ -f /secrets/mysql-secret-reader.txt ]; then
    PASSWORD = $(cat /secrets/mysql-secret-reader.txt)
    echo "Password access successfully"
else
    echo "Password can not fetch from filepath /secrets/mysql-secret-reader.txt"
    exit 1
fi

export MYSQL_ROOT_PASSWORD=$PASSWORD
rm /secrets/mysql-secret-reader.txt
exec /usr/local/bin/docker-entrypoint.sh mysqld

# Important Notes:

# Application runtimes (Node.js, Python, Go, Java) usually do not have a default entrypoint script. They execute the application binary directly
# exec node server.js
# exec python -u app.py
# exec ./my-go-binary
# exec java -jar app.jar