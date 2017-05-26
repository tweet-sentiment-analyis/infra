#!/bin/bash
echo "Deleting elastic search domain..."
aws es delete-elasticsearch-domain --domain-name "tweetanalyzer"
echo "Done"