from django.db import models # Import the models module from Django to create database models
from django.utils import timezone # Import timezone to handle time-related fields
from datetime import timedelta # Import timedelta for time calculations

class MonitoredServer(model.Model):
    STATUS_CHOICES = [
        ('HEALTHY', 'Healthy'), # Status indicating the server is operating normally
        ('UNSTABLE', 'Unstable'), # Status indicating the server is experiencing issues but is still operational
        ('DOWN', 'Down'), # Status indicating the server is not operational
        ('UNREACHABLE', 'Unreachable'), # Status indicating the server cannot be reached
        ('MAINTENANCE', 'Maintenance'), # Status indicating the server is under maintenance
    ]
    
    name = models.CharField(max_length=100, unique=True) # Name of the monitored server
    ip_address = models.GenericIPAddressField(unique=True) # IP address of the monitored server
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='HEALTHY') # Current status of the server
    last_heartbeat = models.DateTimeField(auto_now=True) # Timestamp of the last heartbeat received from the server
    cpu_usage = models.FloatField(default=0.0) # Current CPU usage percentage
    ram_usage = models.FloatField(default=0.0) # Current memory usage percentage
    disk_usage = models.FloatField(default=0.0) # Current disk usage percentage
    
    def __str__(self):
        return f"{self.name} ({self.ip_address}) - {self.status}" # String representation of the monitored server
    
    @property
    def is_timed_out(self):
        # If no heartbeat for > 30 seconds, consider the server unreachable
        if  not self.last_heartbeat:
            return True
        return timezone.now() - self.last_heartbeat > timedelta(seconds=30) # Check if the server has timed out based on the last heartbeat timestamp