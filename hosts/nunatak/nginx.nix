{ self, ... }:
let
  domain = "git.xeondev.com";
in
{
  imports = [
    (self + /modules/nginx.nix)
  ];

  services.nginx.appendHttpConfig = ''
    map $http_origin $allow_origin {
      ~^https://(?:.+\.)?${domain}$ $http_origin;
    }

    map $http_origin $allow_methods {
      ~^https://(?:.+\.)?${domain}$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
    }
  '';

}
