class User < ActiveRecord::Base

	def self.create_user(username, email, password, password_confirm)
		return false if password != password_confirm
		return false if User.where(username: username).to_a.size > 0

		salt = BCrypt::Engine.generate_salt
		hashed_password = BCrypt::Engine.hash_secret(password, salt)
		new_user = User.create(username: username, email: email, password_hash: hashed_password, salt: salt)
		new_user
	end

	def self.authenticate(username, password)
		user = User.where(username:username, password:pass)
		if user.present? && user.password == BCrypt::Engine.hash_secret(password, user.salt)
			user
		else
			nil
		end
	end
end
