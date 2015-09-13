debug 'Installing gsutil'

export PATH=${PATH}:$WERCKER_CACHE_DIR/gsutil
if ! type gsutil > /dev/null -o \
  `gsutil version|awk '{print $3}'|tr -d "\\r\\n"` != \
  `curl -sI https://storage.googleapis.com/pub/gsutil.tar.gz|grep x-goog-meta-gsutil_version|awk '{print $2}'|tr -d "\\r\\n"`; then
curl -sO https://storage.googleapis.com/pub/gsutil.tar.gz
rm -rf $WERCKER_CACHE_DIR/gsutil
tar xfz gsutil.tar.gz -C $WERCKER_CACHE_DIR
fi

debug 'setting gsutil'

sed -i "/^\[Credentials\]/,/^gs_oauth2_refresh_token/ s/^\(gs_oauth2_refresh_token =\).*/\1 $WERCKER_GCS_WEBSITE_DEPLOY_TOKEN/" .boto
sed -i "/^\[GSUtil\]/,/^default_project_id/ s/^\(default_project_id =\).*/\1 $WERCKER_GCS_WEBSITE_DEPLOY_PROJECT/" .boto
export BOTO_PATH=$PWD/.boto

# if WERCKER_GCS_WEBSITE_DEPLOY_INITIALIZE is not empty
if [ -n "$WERCKER_GCS_WEBSITE_DEPLOY_DIR" ]; then
  debug 'Initial setting bucket'
  # if WERCKER_GCS_WEBSITE_DEPLOY_LOCATION is empty
  [ -z "$WERCKER_GCS_WEBSITE_DEPLOY_LOCATION" ] &&
    WERCKER_GCS_WEBSITE_DEPLOY_LOCATION=US
gsutils mb -l $WERCKER_GCS_WEBSITE_DEPLOY_LOCATION gs://$WERCKER_GCS_WEBSITE_DEPLOY_BUCKET
gsutil web set -m index.html -e 404.html gs://$WERCKER_GCS_WEBSITE_DEPLOY_BUCKET
gsutil defacl ch -u AllUsers:R gs://$WERCKER_GCS_WEBSITE_DEPLOY_BUCKET
fi

debug 'Starting deployment'

# if WERCKER_GCS_WEBSITE_DEPLOY_DIR is empty
[ -z "$WERCKER_GCS_WEBSITE_DEPLOY_DIR" ] &&
  WERCKER_GCS_WEBSITE_DEPLOY_DIR=public

gsutil -m rsync -r -d $WERCKER_GCS_WEBSITE_DEPLOY_DIR gs://$WERCKER_GCS_WEBSITE_DEPLOY_BUCKET
gsutil -m cp -r -z html,css,js,xml,txt,json,map,svg $WERCKER_GCS_WEBSITE_DEPLOY_DIR/* gs://$WERCKER_GCS_WEBSITE_DEPLOY_BUCKET

success 'Finished'