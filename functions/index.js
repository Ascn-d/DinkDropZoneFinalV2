const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Matchmaking engine that runs every 10 seconds
exports.matchmakingEngine = functions.pubsub
  .schedule('every 10 seconds')
  .onRun(async (context) => {
    console.log('Running matchmaking engine...');
    
    try {
      // Get all waiting queue entries
      const queueSnapshot = await db.collection('matchmaking_queue')
        .where('status', '==', 'waiting')
        .orderBy('joinTime')
        .get();
      
      if (queueSnapshot.empty) {
        console.log('No players in queue');
        return null;
      }
      
      const entries = queueSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      console.log(`Found ${entries.length} players in queue`);
      
      // Group by match type
      const groupedEntries = entries.reduce((acc, entry) => {
        if (!acc[entry.matchType]) {
          acc[entry.matchType] = [];
        }
        acc[entry.matchType].push(entry);
        return acc;
      }, {});
      
      // Process each match type
      for (const [matchType, players] of Object.entries(groupedEntries)) {
        await processMatchType(matchType, players);
      }
      
      return null;
    } catch (error) {
      console.error('Matchmaking engine error:', error);
      return null;
    }
  });

async function processMatchType(matchType, players) {
  const playersPerMatch = matchType === 'doubles' ? 4 : 2;
  
  if (players.length < playersPerMatch) {
    console.log(`Not enough players for ${matchType} (need ${playersPerMatch}, have ${players.length})`);
    return;
  }
  
  // Simple matchmaking: pair players with similar ELO
  const sortedPlayers = players.sort((a, b) => a.joinTime - b.joinTime);
  
  while (sortedPlayers.length >= playersPerMatch) {
    const matchPlayers = sortedPlayers.splice(0, playersPerMatch);
    await createMatchProposal(matchType, matchPlayers);
  }
}

async function createMatchProposal(matchType, players) {
  const proposalId = admin.firestore().collection('match_proposals').doc().id;
  const expiresAt = new Date(Date.now() + 30000); // 30 seconds
  
  const proposal = {
    id: proposalId,
    matchType: matchType,
    playerIds: players.map(p => p.userId),
    playerNames: players.map(p => p.userDisplayName),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: expiresAt,
    responses: {},
    status: 'pending'
  };
  
  const batch = db.batch();
  
  // Create proposal
  const proposalRef = db.collection('match_proposals').doc(proposalId);
  batch.set(proposalRef, proposal);
  
  // Mark queue entries as matched
  for (const player of players) {
    const queueRef = db.collection('matchmaking_queue').doc(player.id);
    batch.update(queueRef, { status: 'matched' });
  }
  
  await batch.commit();
  
  console.log(`Created match proposal ${proposalId} for ${players.length} players`);
  
  // Send push notifications
  await sendMatchProposalNotifications(players, proposal);
}

async function sendMatchProposalNotifications(players, proposal) {
  for (const player of players) {
    try {
      // Get user's FCM token
      const userDoc = await db.collection('users').doc(player.userId).get();
      const userData = userDoc.data();
      
      if (userData && userData.fcmToken) {
        const otherPlayers = players.filter(p => p.userId !== player.userId);
        const opponentNames = otherPlayers.map(p => p.userDisplayName).join(', ');
        
        const message = {
          token: userData.fcmToken,
          notification: {
            title: '⚡ Match Found!',
            body: `You've been matched with ${opponentNames} for a ${proposal.matchType} game`
          },
          data: {
            type: 'match_proposal',
            proposalId: proposal.id,
            matchType: proposal.matchType
          },
          android: {
            priority: 'high'
          },
          apns: {
            headers: {
              'apns-priority': '10'
            },
            payload: {
              aps: {
                sound: 'default',
                badge: 1
              }
            }
          }
        };
        
        await admin.messaging().send(message);
        console.log(`Sent notification to ${player.userDisplayName}`);
      }
    } catch (error) {
      console.error(`Failed to send notification to ${player.userDisplayName}:`, error);
    }
  }
}

// Clean up expired proposals
exports.cleanupExpiredProposals = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context) => {
    console.log('Cleaning up expired proposals...');
    
    const now = admin.firestore.Timestamp.now();
    const expiredProposals = await db.collection('match_proposals')
      .where('expiresAt', '<', now)
      .where('status', '==', 'pending')
      .get();
    
    if (expiredProposals.empty) {
      return null;
    }
    
    const batch = db.batch();
    
    for (const doc of expiredProposals.docs) {
      const proposal = doc.data();
      
      // Mark proposal as expired
      batch.update(doc.ref, { status: 'expired' });
      
      // Put players back in queue
      for (const playerId of proposal.playerIds) {
        const queueQuery = await db.collection('matchmaking_queue')
          .where('userId', '==', playerId)
          .where('status', '==', 'matched')
          .get();
        
        for (const queueDoc of queueQuery.docs) {
          batch.update(queueDoc.ref, { status: 'waiting' });
        }
      }
    }
    
    await batch.commit();
    console.log(`Cleaned up ${expiredProposals.size} expired proposals`);
    
    return null;
  });

// Analytics and monitoring
exports.logAlphaMetrics = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    try {
      const queueSize = await getQueueSize();
      const activeProposals = await getActiveProposals();
      const recentMatches = await getRecentMatches();
      
      const metrics = {
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        queueSize: queueSize,
        activeProposals: activeProposals,
        recentMatches: recentMatches
      };
      
      await db.collection('system_metrics').add(metrics);
      console.log('Logged alpha metrics:', metrics);
      
    } catch (error) {
      console.error('Error logging metrics:', error);
    }
    
    return null;
  });

async function getQueueSize() {
  const snapshot = await db.collection('matchmaking_queue')
    .where('status', '==', 'waiting')
    .get();
  return snapshot.size;
}

async function getActiveProposals() {
  const snapshot = await db.collection('match_proposals')
    .where('status', '==', 'pending')
    .get();
  return snapshot.size;
}

async function getRecentMatches() {
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
  const snapshot = await db.collection('matches')
    .where('createdAt', '>', oneHourAgo)
    .get();
  return snapshot.size;
}
