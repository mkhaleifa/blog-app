import { Router } from 'express'
import { body } from 'express-validator'
import { getPosts, getPost, createPost, updatePost, deletePost, getMyPosts, likePost } from '../controllers/postController'
import { protect } from '../middleware/auth'

const router = Router()

const postValidation = [
  body('title').trim().notEmpty().withMessage('Title is required').isLength({ max: 150 }),
  body('content').notEmpty().withMessage('Content is required'),
]

router.get('/', getPosts)
router.get('/my', protect, getMyPosts)
router.get('/:slug', getPost)
router.post('/', protect, postValidation, createPost)
router.put('/:id', protect, updatePost)
router.delete('/:id', protect, deletePost)
router.post('/:id/like', protect, likePost)

export default router
