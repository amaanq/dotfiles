{ self, ... }:
{
  imports = [
    (self + /modules/nginx.nix)
  ];
  services.nginx.appendHttpConfig = ''
    map $http_origin $allow_origin {
      ~^https://(?:.+\.)?amaanq\.com$ $http_origin;
      ~^https://(?:.+\.)?xeondev\.com$ $http_origin;
      ~^https://(?:.+\.)?libg\.so$ $http_origin;
      default "*";
    }
    map $http_origin $allow_methods {
      ~^https://(?:.+\.)?amaanq\.com$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
      ~^https://(?:.+\.)?xeondev\.com$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
      ~^https://(?:.+\.)?libg\.so$ "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
      default "CONNECT, DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT, TRACE";
    }
  '';
}
