const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { createLogger, format, transports } = require('winston');

const logger = createLogger({
    transports: [
        new transports.Console()
    ]
});

module.exports = logger;

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// In-memory storage for holiday packages
let holidayPackages = [];
let nextId = 1;

// Initialize with sample data
const initSampleData = () => {
    if (process.env.NODE_ENV !== 'production') {
        holidayPackages = [
            {
                id: nextId++,
                destination: 'Bali, Indonesia',
                price: 1299.99,
                duration_days: 7,
                availability: 15,
                description: 'Tropical paradise with beautiful beaches and rich culture',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Paris, France',
                price: 899.50,
                duration_days: 5,
                availability: 8,
                description: 'City of love with iconic landmarks and world-class cuisine',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Tokyo, Japan',
                price: 1599.00,
                duration_days: 10,
                availability: 12,
                description: 'Modern metropolis blending tradition and innovation',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Santorini, Greece',
                price: 1150.75,
                duration_days: 6,
                availability: 10,
                description: 'Stunning sunsets and white-washed buildings on volcanic cliffs',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Rhyl, Wales',
                price: 499.99,
                duration_days: 3,
                availability: 20,
                description: 'Charming coastal town with sandy beaches and family-friendly attractions',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Blackpool, England',
                price: 59.99,
                duration_days: 2,
                availability: 30,
                description: 'Famous seaside resort with amusement parks and vibrant nightlife',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Edinburgh, Scotland',
                price: 349.99,
                duration_days: 4,
                availability: 25,
                description: 'Historic city with stunning architecture and rich heritage',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Dublin, Ireland',
                price: 399.99,
                duration_days: 3,
                availability: 18,
                description: 'Lively capital known for its friendly locals and vibrant culture',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Amsterdam, Netherlands',
                price: 749.99,
                duration_days: 5,
                availability: 15,
                description: 'Picturesque canals and world-renowned museums',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            },
            {
                id: nextId++,
                destination: 'Barcelona, Spain',
                price: 899.00,
                duration_days: 6,
                availability: 20,
                description: 'Architectural wonders and beautiful Mediterranean beaches',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            }
        ];
        logger.info('Sample data initialized');
    }
};

// GET /packages - Get all holiday packages
app.get('/packages', (req, res) => {
    try {
        // Sort by id to maintain consistent ordering
        const sortedPackages = [...holidayPackages].sort((a, b) => a.id - b.id);
        logger.info('Fetched packages:', sortedPackages.length);
        res.json(sortedPackages);
    } catch (err) {
        logger.error('Error fetching packages:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// GET /packages/:id - Get a specific holiday package
app.get('/packages/:id', (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const package = holidayPackages.find(pkg => pkg.id === id);

        if (!package) {
            return res.status(404).json({error: 'Package not found'});
        }

        res.json(package);
    } catch (err) {
        logger.error('Error fetching package:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// POST /packages - Create a new holiday package
app.post('/packages', (req, res) => {
    try {
        const {destination, price, duration_days, availability, description} = req.body;

        // Basic validation
        if (!destination || !price || !duration_days || availability === undefined) {
            return res.status(400).json({
                error: 'Missing required fields: destination, price, duration_days, availability'
            });
        }

        const newPackage = {
            id: nextId++,
            destination,
            price: parseFloat(price),
            duration_days: parseInt(duration_days),
            availability: parseInt(availability),
            description: description || null,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };

        holidayPackages.push(newPackage);
        logger.info('Created new package:', newPackage.id);
        res.status(201).json(newPackage);
    } catch (err) {
        logger.error('Error creating package:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// PUT /packages/:id - Update a holiday package
app.put('/packages/:id', (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const {destination, price, duration_days, availability, description} = req.body;

        // Basic validation
        if (!destination || !price || !duration_days || availability === undefined) {
            return res.status(400).json({
                error: 'Missing required fields: destination, price, duration_days, availability'
            });
        }

        const packageIndex = holidayPackages.findIndex(pkg => pkg.id === id);

        if (packageIndex === -1) {
            return res.status(404).json({error: 'Package not found'});
        }

        // Update the package while preserving created_at
        holidayPackages[packageIndex] = {
            ...holidayPackages[packageIndex],
            destination,
            price: parseFloat(price),
            duration_days: parseInt(duration_days),
            availability: parseInt(availability),
            description: description || null,
            updated_at: new Date().toISOString()
        };

        logger.info('Updated package:', id);
        res.json(holidayPackages[packageIndex]);
    } catch (err) {
        logger.error('Error updating package:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// DELETE /packages/:id - Delete a holiday package
app.delete('/packages/:id', (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const packageIndex = holidayPackages.findIndex(pkg => pkg.id === id);

        if (packageIndex === -1) {
            return res.status(404).json({error: 'Package not found'});
        }

        const deletedPackage = holidayPackages.splice(packageIndex, 1)[0];
        logger.info('Deleted package:', id);
        res.json({message: 'Package deleted successfully', package: deletedPackage});
    } catch (err) {
        logger.error('Error deleting package:', err);
        res.status(500).json({error: 'Internal server error'});
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({status: 'OK', timestamp: new Date().toISOString()});
});

const startServer = () => {
    initSampleData();
    app.listen(port, () => {
        logger.info(`Holiday packages API running on port ${port}`);
        logger.info(`Health check: http://localhost:${port}/health`);
        logger.info(`API endpoints:`);
        logger.info(`  GET    /packages     - Get all packages`);
        logger.info(`  GET    /packages/:id - Get package by ID`);
        logger.info(`  POST   /packages     - Create new package`);
        logger.info(`  PUT    /packages/:id - Update package`);
        logger.info(`  DELETE /packages/:id - Delete package`);
    });
};

startServer();
