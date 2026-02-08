const { prisma } = require('../config/prisma');

/**
 * Validates that the user has an organization and adds it to the request.
 * Use after authenticateToken.
 */
const validateOrganization = async (req, res, next) => {
  try {
    if (!req.organizationId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Organization not found in token'
      });
    }

    const organization = await prisma.organization.findUnique({
      where: { id: req.organizationId },
      select: { id: true, name: true }
    });

    if (!organization) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Organization not found'
      });
    }

    req.organization = organization;
    next();
  } catch (err) {
    console.error('Organization middleware error:', err);
    return res.status(500).json({
      error: 'Server error',
      message: 'Failed to validate organization'
    });
  }
};

/** Requires user role owner or admin. Use after authenticateToken. */
const requireOwnerOrAdmin = (req, res, next) => {
  if (!req.user || !['owner', 'admin'].includes(req.user.role)) {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Owner or admin role required'
    });
  }
  next();
};

module.exports = { validateOrganization, requireOwnerOrAdmin };
