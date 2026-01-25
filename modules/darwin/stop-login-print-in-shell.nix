{
  # Create .hushlogin for all users to suppress login message
  system.activationScripts.postActivation.text = ''
    for user_home in /Users/*; do
      if [ -d "$user_home" ]; then
        touch "$user_home/.hushlogin"
      fi
    done
  '';
}
