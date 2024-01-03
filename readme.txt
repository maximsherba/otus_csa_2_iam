Для возможности логина через консоль необходимо создать сущность aws_iam_user_login_profile с привязкой ключа из файла public.gpg:
gpg --generate-key
gpg --export | base64 > public.gpg

Получить расшифрованный пароль:
export $(terraform output | sed 's/ //g' | sed 's/"//g')
echo $free_user_password | base64 -d | gpg -d
