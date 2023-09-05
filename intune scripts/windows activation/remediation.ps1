# Remove the active product key with slmgr (suppressed from output)
slmgr //b /upk
# Remove the name of the KMS server 
slmgr //b /ckms
# Add the new product key
slmgr //b /ipk "<product key>"