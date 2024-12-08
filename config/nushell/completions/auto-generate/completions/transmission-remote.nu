# Add torrents to transmission
extern "transmission-remote" [
	--add(-a)					# Add torrents to transmission
	--debug(-b)					# Enable debugging mode
	--alt-speed					# Use the alternate Limits
	--no-alt-speed					# Dont use the alternate Limits
	--alt-speed-downlimit					# Limit the alternate download speed
	--alt-speed-uplimit					# Limit the alternate upload speed
	--alt-speed-scheduler					# Use the scheduled on/off times
	--no-alt-speed-scheduler					# Dont use the scheduled on/off times
	--alt-speed-time-begin					# Time to start using the alt speed limits (in)
	--alt-speed-time-end					# Time to stop using the alt speed limits (hhmm)
	--alt-speed-days					# Number of days to enable the speed scheduler
	--torrent-done-script					# Script to run each time a torrent finishes
	--no-torrent-done-script					# Dont run any script when a torrent finishes
	--incomplete-dir(-c)					# Directory for incomplete downloads
	--no-incomplete-dir(-C)					# Dont store incomplete torrents in a different directory
	--downlimit(-d)					# Limit the maximum download speed to limit
	--no-downlimit(-D)					# Disable download speed limits
	--cache(-e)					# Set the sessions maximum memory cache size (MiB)
	--encryption-required					# Encrypt all peer connections
	--encryption-preferred					# Prefer encrypted peer connections
	--encryption-tolerated					# Prefer unencrypted peer connections
	--exit					# Tell the Transmission to initiate a shutdown
	--files(-f)					# Get a file list for the current torrent(s)
	--get(-g)					# Mark file(s) for download
	--no-get(-G)					# Mark file(s) for not downloading
	--global-seedratio					# Ratio All torrents should seed
	--no-global-seedratio					# All torrents should seed regardless of ratio
	--help(-h)					# Print command-line option descriptions
	--info(-i)					# Show details of the current torrent(s)
	--session-info					# List session information from the server
	--session-stats					# List statistical information from the server
	--list(-l)					# List all torrents
	--portmap(-m)					# Enable portmapping via NAT-PMP or UPnP
	--no-portmap(-M)					# Disable portmapping
	--auth(-n)					# Set the username:password for authentication
	--authenv					# Set the authentication information from $TR_AUTH
	--netrc(-N)					# Set authentication information from a netrc file
	--dht(-o)					# Enable distributed hash table (DHT)
	--no-dht(-O)					# Disable distribued hash table (DHT)
	--port(-p)					# Set the port to use when listening
	--bandwidth-high					# Give this torrent high bandwidth
	--bandwidth-normal					# Give this torrent normal bandwidth
	--bandwidth-low					# Give this torrent low bandwidth
	--priority-high					# Try to download the specified files first
	--priority-normal					# Try to download the specified files normally
	--priority-low					# Try to download the specified files last
	--peers					# Set the maximum number of peers
	--remove(-r)					# Remove the current torrents
	--remove-and-delete					# Remove the current torrents and delete data
	--reannounce					# Reannounce the current torrents
	--move					# Move the current torrents data to another directory
	--find					# Where to look for the current torrents data
	--seedratio					# Current torrents seed until a specific ratio
	--no-seedratio					# Current torrents seed regardless of ratio
	--seedratio-default					# Current torrents use global seedratio
	--tracker-add					# Add a tracker to a torrent
	--tracker-remove					# Remove a tracker from a torrent
	--start(-s)					# Start the current torrents
	--stop(-S)					# Stop the current torrents
	--start-paused					# Start added torrents paused
	--no-start-paused					# Start added torrents unpaused
	--torrent(-t)					# Set torrents as current for subsequent options
	--trash-torrent					# Delete torrents after adding
	--no-trash-torrent					# Do not delete torrents after adding
	--honor-session					# Current torrents honor session limits
	--no-honor-session					# Make the current torrent(s) not honor the session limits
	--uplimit(-u)					# Limit the maximum upload speed (KiB/s)
	--no-uplimit(-U)					# Disable upload speed limits
	--utp					# Enable uTP for peer connections
	--no-utp					# Disable uTP for peer connections
	--verify(-v)					# Verify the current torrents
	--version(-V)					# Show version number and exit
	--download-dir(-w)					# Use directory as default for new downloads
	--pex(-x)					# Enable peer exchange (PEX)
	--no-pex(-X)					# Disable peer exchange (PEX)
	--lds(-y)					# Enable local peer discovery (LPD)
	--no-lds(-Y)					# Disable local peer discovery (LPD)
	--peer-info					# List the current torrents connected peers
	...args
]