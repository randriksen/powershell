# First get the active license object from the computer
$license = get-ciminstance softwarelicensingproduct | where-object {$_.PartialProductKey}
# check if the license object is a KMS license
if ($license.description -like "*KMS*") {
    # if it is a KMS license, exit with error code 1
 exit 1
} else {
    # if it is not a KMS license, exit with error code 0
 exit 0
}