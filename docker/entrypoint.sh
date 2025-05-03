#!/bin/bash
# Use env to find Python - more portable
exec /usr/bin/env python3 -m awslambdaric app.handler
