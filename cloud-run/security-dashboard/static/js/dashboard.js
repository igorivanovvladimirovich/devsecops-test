// Dashboard JavaScript
let refreshInterval;

// Initialize dashboard
document.addEventListener('DOMContentLoaded', function() {
    loadDashboard();
    refreshInterval = setInterval(loadDashboard, 30000); // Refresh every 30 seconds
});

async function loadDashboard() {
    await loadSummary();
    await loadVulnerabilities();
    await loadAPTIndicators();
    await loadCompliance();
    await loadTrends();
}

async function loadSummary() {
    try {
        const response = await fetch('/api/vulnerabilities/summary');
        const data = await response.json();
        
        let criticalCount = 0;
        let highCount = 0;
        let mediumCount = 0;
        
        data.forEach(item => {
            if (item.severity === 'CRITICAL') criticalCount = item.count;
            if (item.severity === 'HIGH') highCount = item.count;
            if (item.severity === 'MEDIUM') mediumCount = item.count;
        });
        
        document.getElementById('critical-count').textContent = criticalCount;
        document.getElementById('high-count').textContent = highCount;
        document.getElementById('medium-count').textContent = mediumCount;
        
        // Load APT count
        const aptResponse = await fetch('/api/apt/summary');
        const aptData = await aptResponse.json();
        const totalAPT = aptData.reduce((sum, item) => sum + item.count, 0);
        document.getElementById('apt-count').textContent = totalAPT;
        
        // Show alert if APT detected
        if (totalAPT > 0) {
            showAPTAlert(aptData);
        }
    } catch (error) {
        console.error('Error loading summary:', error);
    }
}

async function loadVulnerabilities() {
    try {
        const response = await fetch('/api/vulnerabilities/recent?limit=20');
        const data = await response.json();
        
        const tbody = document.getElementById('vulnerabilities-table');
        tbody.innerHTML = '';
        
        data.forEach(vuln => {
            const row = tbody.insertRow();
            row.innerHTML = `
                <td>${new Date(vuln.scan_time).toLocaleString()}</td>
                <td><span class="badge badge-${vuln.severity.toLowerCase()}">${vuln.severity}</span></td>
                <td>${vuln.resource_namespace}/${vuln.resource_name}</td>
                <td>${vuln.vulnerability_id}</td>
                <td>${vuln.package_name} (${vuln.installed_version})</td>
                <td>${vuln.cvss_score.toFixed(1)}</td>
            `;
        });
        
        // Load top packages
        const packagesResponse = await fetch('/api/vulnerabilities/top-packages');
        const packagesData = await packagesResponse.json();
        
        const packagesList = document.getElementById('top-packages-list');
        packagesList.innerHTML = '';
        
        packagesData.forEach(pkg => {
            packagesList.innerHTML += `
                <div class="card mb-2">
                    <div class="card-body">
                        <h6>${pkg.package_name}</h6>
                        <p class="mb-1">
                            <span class="badge bg-danger">${pkg.vulnerability_count} vulnerabilities</span>
                            <span class="badge bg-warning">Max CVSS: ${pkg.max_cvss.toFixed(1)}</span>
                        </p>
                    </div>
                </div>
            `;
        });
    } catch (error) {
        console.error('Error loading vulnerabilities:', error);
    }
}

async function loadAPTIndicators() {
    try {
        const response = await fetch('/api/apt/indicators');
        const data = await response.json();
        
        const tbody = document.getElementById('apt-table');
        tbody.innerHTML = '';
        
        if (data.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="text-center text-success">No APT indicators detected ✓</td></tr>';
            return;
        }
        
        data.forEach(indicator => {
            const row = tbody.insertRow();
            const typeIcon = getAPTTypeIcon(indicator.indicator_type);
            row.innerHTML = `
                <td>${new Date(indicator.detection_time).toLocaleString()}</td>
                <td>${typeIcon} ${indicator.indicator_type}</td>
                <td>${indicator.resource_name}</td>
                <td>${indicator.namespace}</td>
                <td><span class="badge bg-danger">${indicator.risk_score}</span></td>
                <td><small>${JSON.stringify(indicator.details)}</small></td>
            `;
        });
    } catch (error) {
        console.error('Error loading APT indicators:', error);
    }
}

async function loadCompliance() {
    try {
        const response = await fetch('/api/resources/compliance');
        const data = await response.json();
        
        const tbody = document.getElementById('compliance-table');
        tbody.innerHTML = '';
        
        data.forEach(resource => {
            const row = tbody.insertRow();
            const statusBadge = getComplianceBadge(resource.compliance_status);
            row.innerHTML = `
                <td>${resource.namespace}</td>
                <td>${resource.name}</td>
                <td>${new Date(resource.last_scan).toLocaleString()}</td>
                <td>${resource.high_severity_count}</td>
                <td>${statusBadge}</td>
            `;
        });
    } catch (error) {
        console.error('Error loading compliance:', error);
    }
}

async function loadTrends() {
    try {
        const response = await fetch('/api/trends/daily');
        const data = await response.json();
        
        // Process data for Chart.js
        const dates = [...new Set(data.map(item => item.date))].sort();
        const severities = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
        const datasets = severities.map(severity => {
            const color = getSeverityColor(severity);
            return {
                label: severity,
                data: dates.map(date => {
                    const item = data.find(d => d.date === date && d.severity === severity);
                    return item ? item.count : 0;
                }),
                borderColor: color,
                backgroundColor: color + '33',
                tension: 0.1
            };
        });
        
        const ctx = document.getElementById('trendsChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: dates,
                datasets: datasets
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    title: {
                        display: true,
                        text: 'Vulnerability Trends by Severity'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error loading trends:', error);
    }
}

function showAPTAlert(aptData) {
    const alert = document.getElementById('apt-alert');
    const message = document.getElementById('apt-alert-message');
    
    let alertText = 'Detected indicators: ';
    aptData.forEach((item, index) => {
        alertText += `${item.indicator_type} (${item.count} times)`;
        if (index < aptData.length - 1) alertText += ', ';
    });
    
    message.textContent = alertText;
    alert.classList.add('show');
}

function getAPTTypeIcon(type) {
    const icons = {
        'magic_file': '<i class="fas fa-file-code text-danger"></i>',
        'suspicious_port': '<i class="fas fa-network-wired text-warning"></i>',
        'crypto_miner': '<i class="fas fa-coins text-danger"></i>'
    };
    return icons[type] || '<i class="fas fa-exclamation-triangle"></i>';
}

function getComplianceBadge(status) {
    const badges = {
        'COMPLIANT': '<span class="badge bg-success">Compliant</span>',
        'WARNING': '<span class="badge bg-warning">Warning</span>',
        'NON_COMPLIANT': '<span class="badge bg-danger">Non-Compliant</span>'
    };
    return badges[status] || '<span class="badge bg-secondary">Unknown</span>';
}

function getSeverityColor(severity) {
    const colors = {
        'CRITICAL': '#dc3545',
        'HIGH': '#fd7e14',
        'MEDIUM': '#ffc107',
        'LOW': '#6c757d'
    };
    return colors[severity] || '#6c757d';
}