{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.foot ];

  environment.etc."xdg/foot/foot.ini".text = ''
    font=Berkeley Mono Book:size=11,Symbols Nerd Font Mono:size=11
    initial-window-size-pixels=800x600
    selection-target=clipboard

    [bell]
    system=no
    urgent=yes

    [scrollback]
    lines=500000
    multiplier=5.0

    [cursor]
    style=block
    blink=yes
    blink-rate=750

    [mouse]
    hide-when-typing=yes

    [colors-dark]
    foreground=e0def4
    background=191724
    selection-foreground=e0def4
    selection-background=403d52
    cursor=e0def4 524f67
    urls=c4a7e7
    regular0=26233a
    bright0=6e6a86
    regular1=eb6f92
    bright1=eb6f92
    regular2=31748f
    bright2=31748f
    regular3=f6c177
    bright3=f6c177
    regular4=9ccfd8
    bright4=9ccfd8
    regular5=c4a7e7
    bright5=c4a7e7
    regular6=ebbcba
    bright6=ebbcba
    regular7=e0def4
    bright7=e0def4

    [csd]
    preferred=none
    size=0
    border-width=1
    border-color=ff403d52
  '';
}
