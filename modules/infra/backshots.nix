{
  services.borgbackup.repos.main = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJjb4KETwx8uL4vC2stu1QlpwKcJv9xBUr7+Nn57A225"
    ];
    path = "/var/lib/borg/main";
    user = "backshots";
    allowSubRepos = true;
    quota = "400G";
  };
}
