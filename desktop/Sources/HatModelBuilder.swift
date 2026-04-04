import SceneKit

class HatModelBuilder {
    static let shared = HatModelBuilder()

    private func mat(_ color: NSColor, roughness: Float = 0.7, metalness: Float = 0.1) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.roughness.contents = NSNumber(value: roughness)
        m.metalness.contents = NSNumber(value: metalness)
        m.lightingModel = .physicallyBased
        return m
    }

    func build(hat: String) -> SCNNode? {
        switch hat {
        case "crown":     return buildCrown()
        case "tophat":    return buildTopHat()
        case "propeller": return buildPropeller()
        case "halo":      return buildHalo()
        case "wizard":    return buildWizard()
        case "beanie":    return buildBeanie()
        case "tinyduck":  return buildTinyDuck()
        default:          return nil
        }
    }

    // MARK: - Crown

    private func buildCrown() -> SCNNode {
        let root = SCNNode()
        let gold = mat(NSColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0), roughness: 0.3, metalness: 0.6)

        // Band
        let band = SCNCylinder(radius: 0.18, height: 0.08)
        band.firstMaterial = gold
        let bandNode = SCNNode(geometry: band)
        root.addChildNode(bandNode)

        // Points
        for i in 0..<5 {
            let angle = Float(i) * Float.pi * 2.0 / 5.0
            let point = SCNCone(topRadius: 0, bottomRadius: 0.04, height: 0.1)
            point.firstMaterial = gold
            let pNode = SCNNode(geometry: point)
            pNode.position = SCNVector3(sin(angle) * 0.14, 0.08, cos(angle) * 0.14)
            root.addChildNode(pNode)
        }

        // Gems
        let gemColors: [NSColor] = [.systemRed, .systemBlue, .systemGreen]
        for (i, color) in gemColors.enumerated() {
            let gem = SCNSphere(radius: 0.02)
            gem.firstMaterial = mat(color, roughness: 0.2, metalness: 0.3)
            let gNode = SCNNode(geometry: gem)
            let angle = Float(i) * Float.pi * 2.0 / 3.0
            gNode.position = SCNVector3(sin(angle) * 0.17, 0.0, cos(angle) * 0.17)
            root.addChildNode(gNode)
        }

        return root
    }

    // MARK: - Top Hat

    private func buildTopHat() -> SCNNode {
        let root = SCNNode()
        let black = mat(NSColor(white: 0.1, alpha: 1.0))

        // Brim
        let brim = SCNCylinder(radius: 0.22, height: 0.02)
        brim.firstMaterial = black
        let brimNode = SCNNode(geometry: brim)
        root.addChildNode(brimNode)

        // Crown
        let crown = SCNCylinder(radius: 0.14, height: 0.2)
        crown.firstMaterial = black
        let crownNode = SCNNode(geometry: crown)
        crownNode.position = SCNVector3(0, 0.11, 0)
        root.addChildNode(crownNode)

        // Band
        let band = SCNCylinder(radius: 0.145, height: 0.03)
        band.firstMaterial = mat(NSColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 1.0))
        let bandNode = SCNNode(geometry: band)
        bandNode.position = SCNVector3(0, 0.03, 0)
        root.addChildNode(bandNode)

        return root
    }

    // MARK: - Propeller

    private func buildPropeller() -> SCNNode {
        let root = SCNNode()

        // Beanie base
        let base = SCNSphere(radius: 0.16)
        base.firstMaterial = mat(NSColor.systemBlue)
        let baseNode = SCNNode(geometry: base)
        baseNode.scale = SCNVector3(1.0, 0.5, 1.0)
        root.addChildNode(baseNode)

        // Hub
        let hub = SCNCylinder(radius: 0.02, height: 0.06)
        hub.firstMaterial = mat(NSColor(white: 0.4, alpha: 1.0), roughness: 0.3, metalness: 0.5)
        let hubNode = SCNNode(geometry: hub)
        hubNode.position = SCNVector3(0, 0.1, 0)
        root.addChildNode(hubNode)

        // Blades
        let propNode = SCNNode()
        propNode.position = SCNVector3(0, 0.14, 0)
        let bladeMat = mat(NSColor.systemRed, roughness: 0.5, metalness: 0.2)
        for i in 0..<3 {
            let blade = SCNBox(width: 0.2, height: 0.01, length: 0.04, chamferRadius: 0.005)
            blade.firstMaterial = bladeMat
            let bNode = SCNNode(geometry: blade)
            bNode.eulerAngles = SCNVector3(0, Float(i) * Float.pi * 2.0 / 3.0, 0)
            bNode.position = SCNVector3(0, 0, 0)
            propNode.addChildNode(bNode)
        }

        // Spin animation
        let spin = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 0.5))
        propNode.runAction(spin)
        root.addChildNode(propNode)

        return root
    }

    // MARK: - Halo

    private func buildHalo() -> SCNNode {
        let root = SCNNode()

        let halo = SCNTorus(ringRadius: 0.18, pipeRadius: 0.025)
        let haloMat = mat(NSColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1.0), roughness: 0.2, metalness: 0.4)
        haloMat.emission.contents = NSColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.5)
        halo.firstMaterial = haloMat
        let haloNode = SCNNode(geometry: halo)
        haloNode.position = SCNVector3(0, 0.08, 0)
        root.addChildNode(haloNode)

        // Gentle bob
        let bob = SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.03, z: 0, duration: 1.5),
            SCNAction.moveBy(x: 0, y: -0.03, z: 0, duration: 1.5)
        ]))
        root.runAction(bob)

        return root
    }

    // MARK: - Wizard Hat

    private func buildWizard() -> SCNNode {
        let root = SCNNode()
        let purple = mat(NSColor(red: 0.4, green: 0.1, blue: 0.6, alpha: 1.0))

        // Brim
        let brim = SCNCylinder(radius: 0.22, height: 0.02)
        brim.firstMaterial = purple
        let brimNode = SCNNode(geometry: brim)
        root.addChildNode(brimNode)

        // Cone
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.14, height: 0.3)
        cone.firstMaterial = purple
        let coneNode = SCNNode(geometry: cone)
        coneNode.position = SCNVector3(0, 0.16, 0)
        root.addChildNode(coneNode)

        // Stars
        let starMat = mat(NSColor(red: 1.0, green: 0.95, blue: 0.3, alpha: 1.0), roughness: 0.2, metalness: 0.4)
        starMat.emission.contents = NSColor(red: 1.0, green: 0.95, blue: 0.3, alpha: 0.4)
        for (y, angle) in [(Float(0.08), Float(0.3)), (Float(0.18), Float(1.8)), (Float(0.12), Float(3.5))] {
            let star = SCNSphere(radius: 0.015)
            star.firstMaterial = starMat
            let sNode = SCNNode(geometry: star)
            sNode.position = SCNVector3(sin(angle) * 0.12, y, cos(angle) * 0.12)
            root.addChildNode(sNode)
        }

        return root
    }

    // MARK: - Beanie

    private func buildBeanie() -> SCNNode {
        let root = SCNNode()

        let beanie = SCNSphere(radius: 0.2)
        beanie.firstMaterial = mat(NSColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0))
        let beanieNode = SCNNode(geometry: beanie)
        beanieNode.scale = SCNVector3(1.0, 0.6, 1.0)
        root.addChildNode(beanieNode)

        // Pom-pom
        let pom = SCNSphere(radius: 0.06)
        pom.firstMaterial = mat(.white)
        let pomNode = SCNNode(geometry: pom)
        pomNode.position = SCNVector3(0, 0.12, 0)
        root.addChildNode(pomNode)

        return root
    }

    // MARK: - Tiny Duck

    private func buildTinyDuck() -> SCNNode {
        let root = SCNNode()
        let yellow = mat(NSColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0))

        let duckBody = SCNSphere(radius: 0.08)
        duckBody.firstMaterial = yellow
        let bodyNode = SCNNode(geometry: duckBody)
        root.addChildNode(bodyNode)

        let duckHead = SCNSphere(radius: 0.05)
        duckHead.firstMaterial = yellow
        let headNode = SCNNode(geometry: duckHead)
        headNode.position = SCNVector3(0, 0.06, 0.04)
        root.addChildNode(headNode)

        let beak = SCNCone(topRadius: 0, bottomRadius: 0.02, height: 0.04)
        beak.firstMaterial = mat(NSColor.orange)
        let beakNode = SCNNode(geometry: beak)
        beakNode.position = SCNVector3(0, 0.05, 0.09)
        beakNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        root.addChildNode(beakNode)

        // Tiny eyes
        for xOff: Float in [-0.02, 0.02] {
            let eye = SCNSphere(radius: 0.01)
            eye.firstMaterial = mat(.black)
            let eNode = SCNNode(geometry: eye)
            eNode.position = SCNVector3(xOff, 0.08, 0.07)
            root.addChildNode(eNode)
        }

        return root
    }

    // MARK: - Accessories

    func buildAccessory(_ type: AccessoryType) -> SCNNode {
        switch type {
        case .umbrella:    return buildUmbrella()
        case .sunglasses:  return buildSunglasses()
        case .scarf:       return buildScarf()
        case .wings:       return buildWings()
        }
    }

    private func buildUmbrella() -> SCNNode {
        let root = SCNNode()

        let canopy = SCNSphere(radius: 0.3)
        canopy.firstMaterial = mat(NSColor.systemBlue)
        let canopyNode = SCNNode(geometry: canopy)
        canopyNode.scale = SCNVector3(1.0, 0.4, 1.0)
        canopyNode.position = SCNVector3(0.4, 1.4, 0)
        root.addChildNode(canopyNode)

        let handle = SCNCylinder(radius: 0.01, height: 0.6)
        handle.firstMaterial = mat(NSColor(white: 0.3, alpha: 1.0))
        let hNode = SCNNode(geometry: handle)
        hNode.position = SCNVector3(0.4, 1.1, 0)
        root.addChildNode(hNode)

        return root
    }

    private func buildSunglasses() -> SCNNode {
        let root = SCNNode()
        let frameMat = mat(NSColor(white: 0.1, alpha: 1.0))

        // Bridge
        let bridge = SCNCylinder(radius: 0.008, height: 0.08)
        bridge.firstMaterial = frameMat
        let bridgeNode = SCNNode(geometry: bridge)
        bridgeNode.position = SCNVector3(0, 0, 0)
        bridgeNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        root.addChildNode(bridgeNode)

        // Lenses
        let lensMat = mat(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8), roughness: 0.1, metalness: 0.3)
        for xOff: Float in [-0.07, 0.07] {
            let lens = SCNCylinder(radius: 0.05, height: 0.01)
            lens.firstMaterial = lensMat
            let lNode = SCNNode(geometry: lens)
            lNode.position = SCNVector3(xOff, 0, 0.005)
            lNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            root.addChildNode(lNode)
        }

        return root
    }

    private func buildScarf() -> SCNNode {
        let root = SCNNode()
        let scarfMat = mat(NSColor.systemRed)

        // Wrap around neck area
        let wrap = SCNTorus(ringRadius: 0.2, pipeRadius: 0.04)
        wrap.firstMaterial = scarfMat
        let wrapNode = SCNNode(geometry: wrap)
        root.addChildNode(wrapNode)

        // Dangling end
        let end = SCNCapsule(capRadius: 0.04, height: 0.2)
        end.firstMaterial = scarfMat
        let endNode = SCNNode(geometry: end)
        endNode.position = SCNVector3(0.15, -0.1, 0.1)
        endNode.eulerAngles = SCNVector3(0.3, 0, 0.2)
        root.addChildNode(endNode)

        return root
    }

    private func buildWings() -> SCNNode {
        let root = SCNNode()
        let wingMat = mat(NSColor(white: 0.95, alpha: 0.8), roughness: 0.3, metalness: 0.1)

        for xSign: Float in [-1, 1] {
            let wing = SCNCone(topRadius: 0, bottomRadius: 0.25, height: 0.35)
            wing.firstMaterial = wingMat
            let wNode = SCNNode(geometry: wing)
            wNode.position = SCNVector3(xSign * 0.3, 0, -0.1)
            wNode.eulerAngles = SCNVector3(0, 0, xSign * 1.2)
            root.addChildNode(wNode)
        }

        // Gentle flap
        let flapUp = SCNAction.rotateBy(x: 0, y: 0, z: 0.15, duration: 0.8)
        let flapDown = SCNAction.rotateBy(x: 0, y: 0, z: -0.15, duration: 0.8)
        root.runAction(SCNAction.repeatForever(SCNAction.sequence([flapUp, flapDown])))

        return root
    }
}
